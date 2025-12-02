# lib/tasks/process_deposits.rake
namespace :apartments do
  desc "Procesar deposits tipo_ingreso==1: calcular cuotas (amount/2000) y actualizar ult_mes_pagado/ult_ano_pagado y comment"
  task process_deposits_tipo1: :environment do
    require "date"

    total_apartments = 0
    total_deposits = 0
    skipped_no_start_date = 0
    skipped_not_divisible = 0
    processed = 0
    updated_apartments = 0

    puts "Iniciando tarea: apartments:process_deposits_tipo1"
    puts "Recorriendo apartments..."

    MESES_CORTOS = %w[ENE FEB MAR ABR MAY JUN JUL AGO SEP OCT NOV DIC]

    Apartment.find_each do |ap|
      total_apartments += 1
      # obtener deposits tipo 1 ordenados por created_at asc
      deposits = Deposit.where(apartment_id: ap.id, tipo_ingreso: 1).order(created_at: :asc)

      if deposits.empty?
          ap.ult_mes_pagado = nil
          ap.ult_ano_pagado = nil
          ap.save!(validate: false)
        next
      end

      puts "Apartment ##{ap.id} (nro #{ap.number}) --> #{deposits.count} deposits tipo 1"
      deposits.each do |d|
        total_deposits += 1

        amount = d.amount.to_i
        if amount <= 0
          puts "  - Deposit ##{d.id} amount <= 0 (#{amount}). Saltando."
          next
        end

        # convertir en cantidad de cuotas: amount / 2000
        if (amount % 2000) != 0
          skipped_not_divisible += 1
          puts "  * Deposit ##{d.id} monto #{amount} NO divisible por 2000. Saltando."
          next
        end

        cuotas = amount / 2000
        # determinar mes/año inicial: el mes siguiente al último pago
        if ap.ult_mes_pagado.present? && ap.ult_ano_pagado.present?
          # base = mes siguiente a ult_mes_pagado/ult_ano_pagado
          base_date = Date.new(ap.ult_ano_pagado.to_i, ap.ult_mes_pagado.to_i, 1) >> 1
        elsif ap.start_date.present?
          # si no hay ultimo pago, usar start_date.prev_month (como indicaste antes)
          base_date = ap.start_date.prev_month.beginning_of_month
          # el primer mes pagado será el mes siguiente a esa fecha:
          base_date = base_date >> 1
        else
          skipped_no_start_date += 1
          puts "  * Apartment ##{ap.id} sin ult_mes_pagado ni start_date. Saltando deposit ##{d.id}."
          next
        end

        first_month = base_date
        last_month = base_date >> (cuotas - 1) # avanzar (cuotas - 1) para obtener mes final

        # --- Formatear meses en abreviatura ---
        primer_str = "#{MESES_CORTOS[first_month.month - 1]}/#{first_month.year}"
        ultimo_str = "#{MESES_CORTOS[last_month.month - 1]}/#{last_month.year}"

        # Formatos para comment: MM/YYYY
        # primer_str = first_month.strftime("%m/%Y")
        # ultimo_str = last_month.strftime("%m/%Y")

        # Actualizar apartment: ult_mes_pagado y ult_ano_pagado con mes/año del último mes pagado
        ap.ult_mes_pagado = last_month.month
        ap.ult_ano_pagado = last_month.year

        d.comment = d.comment.sub(/\s*-.*/, "")
        # Agregar al comment el texto: " -- MES/YYYY a MES/YYYY"
        # Evitar doble append exacto si ya existe la misma secuencia al final
        append_text = " - #{primer_str} a #{ultimo_str}"
        if d.comment.to_s.end_with?(append_text)
          puts "  * Deposit Socio ##{ap.number} - comment ya contiene '#{append_text}', no se duplica."
        else
          d.comment = [ d.comment.to_s, append_text ].join
          puts "  - Deposit Socio ##{ap.number} - #{d.comment}"
        end

        # Guardar sin validar (evita fallos por validaciones ajenas)
        d.save!(validate: false)
        ap.save!(validate: false)

        processed += 1
        updated_apartments += 1
        puts "  - Procesado deposit ##{d.id}: cuotas=#{cuotas}, primer=#{primer_str}, ultimo=#{ultimo_str} -> apartment ##{ap.id} actualizado."
        puts "  - Apartment ##{ap.number} #{ap.ult_mes_pagado} - #{ap.ult_ano_pagado}"
      end
    end

    puts "=== Resumen ==="
    puts "Apartments recorridos: #{total_apartments}"
    puts "Deposits tipo 1 revisados: #{total_deposits}"
    puts "Procesados correctamente: #{processed}"
    puts "Deposits saltados (monto no divisible por 2000): #{skipped_not_divisible}"
    puts "Deposits saltados (sin start_date ni ult_mes): #{skipped_no_start_date}"
    puts "Apartments actualizados: #{updated_apartments}"
    puts "Tarea finalizada."
  end
end
