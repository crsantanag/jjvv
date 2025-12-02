# lib/tasks/apartments_update_description.rake
namespace :apartments do
  desc "Actualizar description = ap_paterno + ap_materno + nombre para todos los apartments"
  task update_description: :environment do
    total = 0
    updated = 0
    errors = 0

    puts "Iniciando apartments:update_description ..."

    Apartment.find_each(batch_size: 500) do |ap|
      total += 1

      begin
        new_description = [ ap.ap_paterno, ap.ap_materno, ap.nombre ]
                            .reject(&:blank?)
                            .join(" ")

        ap.update_columns(
          description: new_description,
          updated_at: Time.current
        )

        updated += 1
        puts "Apartment ##{ap.id} (#{ap.number}) → '#{new_description}'"

      rescue => e
        errors += 1
        puts "❌ Error en apartment ##{ap.id}: #{e.class} - #{e.message}"
      end
    end

    puts "\n--- Resumen ---"
    puts "Apartments procesados: #{total}"
    puts "Apartments actualizados: #{updated}"
    puts "Errores: #{errors}"
    puts "Tarea finalizada."
  end
end
