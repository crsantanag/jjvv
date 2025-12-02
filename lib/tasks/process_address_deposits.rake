# lib/tasks/process_address_deposits.rake
namespace :addresses do
  desc "Procesar deposits por Address: calcular cuotas (amount/2000), actualizar ult_mes_pagado/ult_ano_pagado en Address y anotar comment en Deposit"
  task process_deposits_to_addresses: :environment do
    require "date"

    MESES_CORTOS = %w[ENE FEB MAR ABR MAY JUN JUL AGO SEP OCT NOV DIC]

    total_monto = 0
    total_addresses = 0
    total_deposits_seen = 0
    total_processed = 0
    total_skipped_divisible = 0
    total_skipped_amount = 0
    total_skipped_no_base = 0
    updated_addresses = 0

    puts "Iniciando tarea: addresses:process_deposits_to_addresses"

    Address.find_each do |address|
      total_addresses += 1

      # obtener todos los apartments de la address
      apartment_ids = address.apartments.pluck(:id)
      if apartment_ids.empty?
        # nada que procesar
        next
      end

      # obtener deposits asociados a esos apartments, ordenados por created_at
      deposits = Deposit.where(apartment_id: apartment_ids, tipo_ingreso: 1).order(:created_at)

      next if deposits.empty?

      puts "\nDirección=#{address.street} - familia='#{address.description}' --> #{deposits.count} depósitos a revisar"

      # Procesar cada deposit cronológicamente
      deposits.each do |d|
        total_deposits_seen += 1

        amount = d.amount.to_i
        if amount <= 0
          total_skipped_amount += 1
          puts "  ** Depósito ##{d.id} amount #{amount} inválido (<= 0). Saltando."
          next
        end

        unless (amount % 2000).zero?
          total_skipped_divisible += 1
          puts "  ** Depósito ##{d.id} monto #{amount} NO divisible por 2000. Saltando."
          next
        end

        total_monto += amount
        cuotas = amount / 2000
        # determinar mes/año inicial: el mes siguiente al último pago
        if address.ult_mes_pagado.present? &&  address.ult_ano_pagado.present?
          # base = mes siguiente a ult_mes_pagado/ult_ano_pagado
          base_date = Date.new(address.ult_ano_pagado.to_i, address.ult_mes_pagado.to_i, 1) >> 1
        elsif address.fecha_inicio.present?
          # si no hay ultimo pago, usar fecha_inicio.prev_month (como indicaste antes)
          base_date = address.fecha_inicio.prev_month.beginning_of_month
          # el primer mes pagado será el mes siguiente a esa fecha:
          base_date = base_date >> 1
        else
          skipped_no_start_date += 1
          puts "  ** Dirección ##{address.id} sin ult_mes_pagado ni fecha_inicio. Saltando address ##{d.id}."
          next
        end

        total_processed += 1

        first_month = base_date
        last_month = base_date >> (cuotas - 1) # avanzar (cuotas - 1) para obtener mes final

        primer_str = "#{MESES_CORTOS[first_month.month - 1]}/#{first_month.year}"
        ultimo_str = "#{MESES_CORTOS[last_month.month - 1]}/#{last_month.year}"

        # Actualizar address (ult_mes_pagado / ult_ano_pagado)
        address.ult_mes_pagado = last_month.month
        address.ult_ano_pagado = last_month.year

        # Normalizar y actualizar comment del deposit: eliminar cualquier sufijo previo del patrón " - ... a ..."
        # Buscamos el primer " - " (espacio, guion, espacio) y cortamos desde ahí
        new_comment_base = d.comment.to_s.sub(/\s*-\s*.*/, "").strip

        append_text = " - #{cuotas} cuotas: #{primer_str} a #{ultimo_str}"
        if new_comment_base.end_with?(append_text.strip)
          # ya contiene exactamente el sufijo; no duplicar
          puts "  * Depósito ##{d.id} ya contiene el sufijo '#{append_text.strip}', no duplicando."
        else
          d.comment = [ new_comment_base.presence || "", append_text ].join
          # Guardar: para evitar problemas con validaciones ajenas usamos save! con validate: false
          Address.transaction do
            address.save!(validate: false)
            d.save!(validate: false)
          end
          updated_addresses += 1
          puts "  - Procesado depósito de fecha=#{d.date} monto=#{amount} de=#{d.apartment.description} cuotas=#{cuotas}, #{primer_str} a #{ultimo_str} --> #{address.ult_mes_pagado}/#{address.ult_ano_pagado}"
        end
      end
    end

    puts "\n=== Resumen ==="
    puts "Addresses recorridas: #{total_addresses}"
    puts "Deposits revisados: #{total_deposits_seen}"
    puts "Procesados correctamente: #{total_processed}"
    puts "Saltados (monto <= 0): #{total_skipped_amount}"
    puts "Saltados (no divisible por 2000): #{total_skipped_divisible}"
    puts "Saltados (sin base): #{total_skipped_no_base}"
    puts "Addresses actualizadas (conteo de operaciones): #{updated_addresses}"
    puts "Total pagos: #{total_monto}"
    puts "Tarea finalizada."
  end
end
