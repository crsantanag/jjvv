# lib/tasks/import_socios.rake
require "roo"
require "date"

namespace :update do
  desc "Actualizar solo nombre, ap_paterno y ap_materno de los apartments desde Excel"
  task nombre_socios: :environment do
    file_path = "CARGA_SOCIOS_2.xlsx"

    unless File.exist?(file_path)
      puts "❌ Archivo no encontrado: #{file_path}"
      exit 1
    end

    xlsx = Roo::Spreadsheet.open(file_path)
    header = xlsx.row(1).map { |h| h.to_s.strip }

    stats = { rows: 0, updated: 0, skipped_missing_apartment: 0, errors: 0 }

    (2..xlsx.last_row).each do |i|
      stats[:rows] += 1
      row = Hash[[ header, xlsx.row(i) ].transpose]

      begin
        num_socio  = row["num_socio"].to_s.strip
        nombre     = row["nombre"].to_s.strip
        ap_paterno = row["ap_paterno"].to_s.strip
        ap_materno = row["ap_materno"].to_s.strip

        apartment = Apartment.find_by(number: num_socio)

        if apartment.nil?
          stats[:skipped_missing_apartment] += 1
          puts "⚠️ No existe APARTMENT con num_socio=#{num_socio} (fila #{i}) — se salta."
          next
        end

        apartment.update!(
          nombre:     nombre.upcase,
          ap_paterno: ap_paterno.upcase,
          ap_materno: ap_materno.upcase
        )

        stats[:updated] += 1
        puts "✅ Actualizado Apartment #{apartment.number}: #{ap_paterno} #{ap_materno} #{nombre}"

      rescue => e
        stats[:errors] += 1
        puts "❌ Error en fila #{i}: #{e.class} - #{e.message}"
        next
      end
    end

    puts "\n--- Resumen ---"
    puts "Filas leídas: #{stats[:rows]}"
    puts "Apartments actualizados: #{stats[:updated]}"
    puts "Apartments faltantes: #{stats[:skipped_missing_apartment]}"
    puts "Errores: #{stats[:errors]}"
    puts "Importación finalizada."
  end
end
