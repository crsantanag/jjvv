module DepositsHelper
  def nombre_tipo_ingreso(tipo)
    I18n.t("activerecord.attributes.deposit.tipo_ingreso.#{tipo}", default: tipo.to_s.humanize)
  end
end

def tipo_ingreso_humano(tipo)
  {
    "ingreso_1"  => "Cuota social",
    "ingreso_2"  => "Certificado residencia",
    "ingreso_3"  => "Traspaso Temp → Caja",
    "ingreso_4"  => "Otros ingresos",
    "ingreso_5"  => "Otros egresos"
  }[tipo] || tipo.to_s.humanize
end
