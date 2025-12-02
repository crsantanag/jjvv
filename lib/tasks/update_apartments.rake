namespace :apartments do
  desc "Asignar ult_mes_pagado y ult_ano_pagado restando 1 mes a start_date"
  task update_last_paid: :environment do
    puts "=== Iniciando actualización de apartments ==="

    Apartment.find_each do |ap|
      if ap.start_date.present?
        # restar 1 mes
        fecha = ap.start_date.prev_month

        ap.ult_mes_pagado = fecha.month
        ap.ult_ano_pagado = fecha.year

        ap.save!(validate: false)

        puts "Actualizado apartment ##{ap.id} #{ap.start_date} --> #{fecha.month}-#{fecha.year}"
      else
        puts "Apartment ##{ap.id} SIN start_date — omitido"
        ap.ult_mes_pagado = nil
        ap.ult_ano_pagado = nil

        ap.save!(validate: false)
      end
    end

    puts "=== Proceso terminado ==="
  end
end
