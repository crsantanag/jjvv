# app/services/import_apartments_from_excel.rb
require "roo"

class ImportApartmentsFromExcel
  attr_reader :successful, :failed, :errors

  def initialize(file, current_user = nil)
    @file = file
    @current_user = current_user
    @successful = []
    @failed = []
    @errors = []
  end

  def call
    spreadsheet = Roo::Spreadsheet.open(@file.path)
    header = spreadsheet.row(1)

    (2..spreadsheet.last_row).each do |i|
      row = Hash[[ header, spreadsheet.row(i) ].transpose]

      socio   = row["numero_socio"].to_i
      nombre  = row["nombre"].to_s
      fecha_incorporacion = fecha_incorporacion = row["fecha_i"].is_a?(Date) ? row["fecha_i"] : Date.parse(row["fecha_i"].to_s)

      # Busca por number; si existe lo actualiza, si no lo crea
      apartment = Apartment.find_or_initialize_by(number: socio)

      apartment.assign_attributes(
        description: nombre,
        start_date: fecha_incorporacion,
        user_id: row["user_id"] || @current_user&.id
      )

      if apartment.save
        @successful << apartment
      else
        @failed << row
        @errors << { row: i, messages: apartment.errors.full_messages }
      end
    end

    self
  end
end
