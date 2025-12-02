module BillsHelper
  def tipo_egreso_humano(tipo)
    {
      "egreso_1" => "Rendición",
      "egreso_2" => "Activo fijo",
      "egreso_3" => "Traspaso Banco → Temp",
      "egreso_4" => "Traspaso Caja  → Pago",
      "egreso_5" => "Otro"
    }[tipo] || tipo.to_s.humanize
  end
end
