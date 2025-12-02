# lib/tasks/addresses_update_fecha_inicio.rake
namespace :addresses do
  desc "Para cada address: tomar start_date del apartment con menor number y guardarlo en address.fecha_inicio; dejar ult_mes_pagado y ult_ano_pagado en nil"
  task copia_fecha_inicio_from_apartments: :environment do
    require "active_support/all"

    total = 0
    updated = 0
    skipped_no_apartments = 0
    errors = 0

    puts "Iniciando addresses:copia_fecha_inicio_from_apartments ..."

    Address.find_each(batch_size: 500) do |address|
      total += 1

      begin
        Apartment.transaction do
          # obtener primer apartment por number asc
          first_ap = address.apartments.order(number: :asc).limit(1).first

          if first_ap.nil?
            skipped_no_apartments += 1
            # dejar campos en nil
            address.update_columns(fecha_inicio: nil, ult_mes_pagado: nil, ult_ano_pagado: nil)
            puts "** ERROR Address ##{address.id} ('#{address.street}') -> sin apartments. fecha_inicio=nil, ult_mes_pagado=nil, ult_ano_pagado=nil"
            next
          end

          # tomar start_date del primer apartment (puede ser nil)
          new_fecha_inicio = first_ap.start_date

          # actualizar address: fecha_inicio y limpiar ult_mes/ult_ano
          # usamos update_columns para evitar callbacks/validaciones indeseadas en batch

          address.update_columns(
            description: [ first_ap.ap_paterno, first_ap.ap_materno, first_ap.nombre ]
              .reject(&:blank?)
              .join(" "),
            fecha_inicio: new_fecha_inicio,
            ult_mes_pagado: nil,
            ult_ano_pagado: nil,
            updated_at: Time.current
          )

          updated += 1
          puts "Dirección #{address.street} - #{address.description} --> fecha de inicio=#{new_fecha_inicio.strftime("%d/%m/%Y")} (desde #{first_ap.description} socio=#{first_ap.number})"
        end
      rescue => e
        errors += 1
        puts "** ERROR procesando Address ##{address.id}: #{e.class} #{e.message}"
      end
    end

    puts "\n--- Resumen ---"
    puts "Addresses procesadas: #{total}"
    puts "Addresses actualizadas: #{updated}"
    puts "Addresses sin apartments (se dejaron campos en nil): #{skipped_no_apartments}"
    puts "Errores: #{errors}"
    puts "Tarea finalizada."
  end
end
