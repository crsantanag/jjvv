# app/services/apartment_address_importer.rb
class ApartmentAddressImporter
  # mapping de columnas de la planilla a atributos del apartment
  COLUMN_MAP = {
    num_socio:    :number,
    ap_paterno:   :ap_paterno,
    ap_materno:   :ap_materno,
    nombres:      :nombres,
    edad:         :edad,
    estado_civil: :estado_civil,
    profesion:    :profesion,
    domicilio:    :domicilio,
    rut:          :rut,
    dv:           :dv,
    telefono:     :telefono,
    estado:       :estado
  }.freeze

  # file_path: ruta a archivo .xlsx/.xls/.csv
  # options:
  #   sheet: nombre o índice de hoja (default 0)
  #   street_column: nombre de columna en la planilla que contiene la dirección (default: 'domicilio')
  #   header_row: si la planilla tiene encabezado en la primera fila (default true)
  def self.import(file_path, options = {})
    new(file_path, options).import
  end

  def initialize(file_path, options = {})
    @file_path = file_path
    @sheet = options[:sheet] || 0
    @street_column = (options[:street_column] || "domicilio").to_s
    @header_row = options.fetch(:header_row, true)
    @errors = []
    @stats = { created_addresses: 0, updated_apartments: 0, missing_apartments: 0, rows: 0, failed_rows: 0 }
  end

  def import
    workbook = open_workbook(@file_path)
    sheet = workbook.sheet(@sheet)

    header = if @header_row
               # normalizamos encabezados a símbolos, sin espacios
               sheet.row(1).map { |h| h.present? ? h.to_s.strip.downcase.gsub(" ", "_").to_sym : nil }
    else
               []
    end

    first_data_row = @header_row ? 2 : 1

    (first_data_row..sheet.last_row).each do |i|
      @stats[:rows] += 1
      row = sheet.row(i)
      begin
        ActiveRecord::Base.transaction do
          row_hash = row_to_hash(row, header)
          process_row(row_hash)
        end
      rescue => e
        @stats[:failed_rows] += 1
        @errors << { row: i, error: e.message, backtrace: e.backtrace.first(3) }
        Rails.logger.error("[ApartmentAddressImporter] fila #{i} error: #{e.message}")
      end
    end

    { stats: @stats, errors: @errors }
  end

  private

  def open_workbook(path)
    case File.extname(path).downcase
    when ".xls"  then Roo::Excel.new(path)
    when ".xlsx" then Roo::Excelx.new(path)
    when ".csv"  then Roo::CSV.new(path)
    else
      raise "Formato no soportado: #{path}"
    end
  end

  # convierte la fila a hash con keys simbólicas según header o posición
  def row_to_hash(row, header)
    if header.present?
      Hash[header.zip(row)]
    else
      # Si no hay encabezado, asume orden conocido (ajusta si hace falta)
      Hash[COLUMN_MAP.keys.zip(row)]
    end
  end

  # Procesa una fila: crea address si no existe, actualiza apartment
  def process_row(row_hash)
    # Obtenemos el street (normalizamos espacios)
    street_raw = (row_hash[@street_column.to_sym] || row_hash[@street_column] || row_hash[:domicilio] || row_hash["domicilio"])
    raise "Street vacío" if street_raw.blank?
    street = normalize_street(street_raw)

    # Buscar address por street EXACTO (después de normalizar)
    address = Address.find_by(street: street)
    if address.nil?
      address = Address.create!(street: street)
      @stats[:created_addresses] += 1
      Rails.logger.info("[ApartmentAddressImporter] Se creó Address con street='#{street}' id=#{address.id}")
    end

    # Obtener número de socio (num_socio) y convertir a integer si corresponde
    num_socio_raw = row_hash[:num_socio] || row_hash["num_socio"] || row_hash[:number] || row_hash["number"]
    raise "num_socio vacío" if num_socio_raw.blank?
    num_socio = parse_number(num_socio_raw)

    apartment = Apartment.find_by(number: num_socio)
    if apartment.nil?
      @stats[:missing_apartments] += 1
      Rails.logger.warn("[ApartmentAddressImporter] No se encontró Apartment con number=#{num_socio}. Se omite actualización.")
      return
    end

    # Preparar atributos a actualizar (mapear columnas a atributos del apartment)
    attrs = {}
    COLUMN_MAP.each do |col_sym, attr_sym|
      next if col_sym == :num_socio
      value = row_hash[col_sym] || row_hash[col_sym.to_s] || row_hash[attr_sym] || row_hash[attr_sym.to_s]
      next if value.nil?

      # casteos y limpieza básicos
      case attr_sym
      when :edad
        attrs[:edad] = value.to_i
      when :rut
        # Si guardas rut como integer: convertir, pero ojo con ceros a la izquierda
        attrs[:rut] = value.to_s.gsub(/\D/, "").to_i
      else
        attrs[attr_sym] = value.to_s.strip
      end
    end

    # Asignar address_id
    attrs[:address_id] = address.id

    # Actualizar apartment
    apartment.update!(attrs)
    @stats[:updated_apartments] += 1
    Rails.logger.info("[ApartmentAddressImporter] Actualizado Apartment id=#{apartment.id} number=#{apartment.number} address_id=#{address.id}")
  end

  def normalize_street(s)
    # eliminar espacios al inicio/fin y colapsar múltiples espacios
    s.to_s.strip.gsub(/\s+/, " ")
  end

  def parse_number(val)
    # si viene con decimales (por ejemplo desde Excel), convertir sin decimales
    if val.is_a?(Float)
      val.to_i
    else
      val.to_s.strip.gsub(/\D/, "").to_i
    end
  end
end
