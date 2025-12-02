# lib/tasks/import_socios.rake
require "roo"
require "date"

namespace :import do
  desc "Importar y actualizar addresses y apartments desde Excel (incluye fecha_inicio -> start_date y user_id = 1)"
  task socios: :environment do
    file_path = "CARGA_SOCIOS_Todos.xlsx" # <- cambia si tu archivo tiene otro nombre o ruta

    unless File.exist?(file_path)
      puts "❌ Archivo no encontrado: #{file_path}"
      exit 1
    end

    xlsx = Roo::Spreadsheet.open(file_path)
    header = xlsx.row(1).map { |h| h.to_s.strip }

    stats = { rows: 0, updated: 0, skipped_missing_apartment: 0, address_created: 0, errors: 0 }

    (2..xlsx.last_row).each do |i|
      stats[:rows] += 1
      row = Hash[[ header, xlsx.row(i) ].transpose]

      begin
        num_socio     = row["num_socio"].to_s.strip
        nombre        = row["nombre"].to_s.strip
        ap_paterno    = row["ap_paterno"].to_s.strip
        ap_materno    = row["ap_materno"].to_s.strip
        edad          = row["edad"].to_s.strip == "" ? nil : row["edad"].to_i
        estado_civil  = row["estado_civil"].to_s.strip
        profesion     = row["profesion"].to_s.strip
        domicilio     = row["domicilio"].to_s.strip
        rut           = row["rut"].to_s.strip == "" ? nil : row["rut"].to_s.gsub(/\D/, "").to_i
        dv            = row["dv"].to_s.strip
        telefono      = row["telefono"].to_s.strip
        estado        = row["estado"].to_s.strip

        description   = [ ap_paterno, ap_materno, nombre ]
                        .compact
                        .map { |s| s.strip.gsub(/\s+/, " ") }
                        .join(" ")

        # fecha_inicio -> start_date
        fecha_inicio_raw = row["fecha_inicio"] || row["fecha Inicio"] || row["fecha_inicio".to_sym]
        start_date = parse_excel_date(fecha_inicio_raw)

        # Normalizar domicilio a mayúsculas y colapsar espacios
        domicilio_normalizado = domicilio.to_s.strip.gsub(/\s+/, " ").upcase
        puts "domicilio_normalizado: #{domicilio_normalizado}"
        # Buscar o inicializar Address por street (case-insensitive)
        address = Address.where("UPPER(street) = ?", domicilio_normalizado.upcase).first
        if address.nil?
          address = Address.find_or_initialize_by(street: domicilio_normalizado)
          # Asignar y guardar (si falla validación, update! lanzará excepción)
          address.update!(user_id: 1, description: "#{ap_paterno} #{nombre}".strip.upcase)
          stats[:address_created] += 1
          puts "🆕 Creada Address (fila #{i}): id=#{address.id} street='#{address.street}' description='#{address.description}'"
        else
          # Si nil, "", " " (solo espacios), [] o {} vacíos, sólo entonces lo llena
          if address.description.blank?
             # llenar si está vacio
             address.update!(user_id: 1, description: "#{ap_paterno} #{nombre}".strip.upcase) rescue nil
             puts "⚠️ Actualizada Address (fila #{i}): id=#{address.id} street='#{address.street}' description='#{address.description}'"
          end
        end

        # Buscar apartment por number (num_socio)
        apartment = Apartment.find_by(number: num_socio)
        if apartment.nil?
          stats[:skipped_missing_apartment] += 1
          puts "⚠️  No existe APARTMENT con num_socio=#{num_socio} (fila #{i}) — se salta."
          next
        end

        # Preparar atributos a actualizar
        attrs = {
          user_id:       1,
          address_id:    address.id,
          ap_paterno:    ap_paterno.upcase,
          ap_materno:    ap_materno.upcase,
          nombre:        nombre.upcase,
          description:   description,
          edad:          edad,
          estado_civil:  estado_civil.upcase,
          profesion:     profesion.upcase,
          domicilio:     domicilio_normalizado,
          rut:           rut,
          dv:            dv.upcase,
          telefono:      telefono,
          estado:        estado.upcase
        }
        attrs[:start_date] = start_date if start_date.present?

        apartment.update!(attrs)
        stats[:updated] += 1
        puts "✅ Actualizado Apartment number=#{apartment.number} id=#{apartment.id} -> address_id=#{address.id} (fila #{i})#{start_date.present? ? " start_date=#{start_date}" : ''}"
      rescue => e
        stats[:errors] += 1
        puts "❌ Error en fila #{i} (num_socio=#{row['num_socio']}): #{e.class} - #{e.message}"
        Rails.logger.error "[import:socios] fila #{i} error: #{e.message}\n#{e.backtrace.first(6).join("\n")}"
        next
      end
    end

    puts "\n--- Resumen ---"
    puts "Filas leídas: #{stats[:rows]}"
    puts "Apartments actualizados: #{stats[:updated]}"
    puts "Addresses creadas: #{stats[:address_created]}"
    puts "Apartments faltantes (saltadas): #{stats[:skipped_missing_apartment]}"
    puts "Filas con errores: #{stats[:errors]}"
    puts "Importación finalizada."
  end

  # -----------------------
  # Helper: parsear fecha desde Excel (Roo puede devolver Date, Time, String, o número)
  # -----------------------
  def parse_excel_date(value)
    return nil if value.nil? || value.to_s.strip == ""

    # Si ya es Date o Time
    if value.is_a?(Date)
      value
    elsif value.is_a?(Time)
      value.to_date
    elsif value.is_a?(String)
      s = value.strip
      # Intentar parseos comunes
      formats = [ "%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y", "%m/%d/%Y" ]
      formats.each do |fmt|
        begin
          return Date.strptime(s, fmt)
        rescue
          next
        end
      end
      begin
        Date.parse(s) rescue nil
      rescue
        nil
      end
    elsif value.is_a?(Numeric)
      # Excel serial date (base 1899-12-30)
      begin
        Date.new(1899, 12, 30) + value.to_i
      rescue
        nil
      end
    else
      begin
        Date.parse(value.to_s) rescue nil
      rescue
        nil
      end
    end
  end
end
