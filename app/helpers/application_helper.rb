module ApplicationHelper
  # app/helpers/application_helper.rb
  include BillsHelper
  include DepositsHelper

  def selected_year
    session[:selected_year]
  end

  def selected_year?
    session[:selected_year].present?
  end

  def formato_monto(monto)
    monto ||= 0 # si es nil, lo convertimos a 0
    classes = monto.negative? ? "text-danger" : "text-dark"
    contenido = number_to_currency(monto, unit: "$", delimiter: ".", precision: 0, format: "%u%n")
    tag.span(contenido, class: classes)
  end
end
