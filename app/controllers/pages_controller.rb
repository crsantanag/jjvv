class PagesController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]
  def index
  end

  def balance
  @balance_inicial = session[:balance_inicial]

  year = session[:selected_year]
  fecha_inicio = Date.new(year, 1, 1)
  fecha_fin = Date.new(year, 12, 31)

  # Traemos todos los registros del año (los usamos para construir la lista de meses y para los registros)
  ingresos_all = Deposit.where(date: fecha_inicio..fecha_fin).to_a
  egresos_all  = Bill.where(date: fecha_inicio..fecha_fin).to_a

  # Meses presentes en el año
  all_months = (ingresos_all + egresos_all)
                 .map { |r| r.date.beginning_of_month }
                 .uniq
                 .sort

  @balance_data = all_months.map do |month|
    # Rango del mes (para consultas SQL exactas)
    month_range = month.beginning_of_month..month.end_of_month

    # Registros a mostrar (todos)
    mes_ingresos_records = ingresos_all.select { |i| i.date.beginning_of_month == month }
    mes_egresos_records  = egresos_all.select  { |e| e.date.beginning_of_month == month }

    # Sumas EXCLUYENDO tipo_ingreso = 3 y tipo_egreso = 4 (se hacen en SQL por precisión)
    # Si tus columnas se llaman exactamente :tipo_ingreso / :tipo_egreso esto funcionará.
    # Si se llamaran distinto, reemplaza por el nombre correcto.
    sum_ingresos = Deposit.where(date: month_range).where.not(tipo_ingreso: 3).sum(:amount)
    sum_egresos  = Bill.where(date: month_range).where.not(tipo_egreso: 4).sum(:amount)

    # Orden total del mes por created_at (todos los registros, incluidos los excluidos de las sumas)
    registros_ordenados = (mes_ingresos_records + mes_egresos_records).sort_by(&:created_at)

    {
      mes: month,
      ingresos: sum_ingresos,
      egresos: sum_egresos,
      registros: registros_ordenados
    }
  end

  # Totales anuales (aplicando la misma exclusión, en SQL)
  @total_ingresos = Deposit.where(date: fecha_inicio..fecha_fin).where.not(tipo_ingreso: 3).sum(:amount)
  @total_egresos  = Bill.where(date: fecha_inicio..fecha_fin).where.not(tipo_egreso: 4).sum(:amount)
  @balance_total  = @total_ingresos - @total_egresos

  respond_to do |format|
    format.html
    format.pdf do
      render pdf: "Balance_#{session[:selected_year] || Date.current.year}",
             template: "pages/balance",
             layout: "pdf",
             encoding: "UTF-8",
             page_size: "Letter",
             orientation: "Portrait"
    end
  end
  end




  def set_year
    session[:selected_year] = (params[:year] || Date.today.year).to_i
    year = session[:selected_year]
    fecha_corte = Date.new(year - 1, 12, 31)

    # ingresos = current_user.deposits.where("date <= ?", fecha_corte).sum(:amount)
    ingresos = Deposit.where("date <= ?", fecha_corte).sum(:amount)
    # egresos = current_user.bills.where("date <= ?", fecha_corte).sum(:amount)
    egresos = Bill.where("date <= ?", fecha_corte).sum(:amount)

    session[:balance_inicial] = current_user.saldo_inicial + ingresos - egresos

    if params[:year].present?
          flash[:notice] = "AÑO SELECCIONADO - #{year}"
    end
    redirect_to request.referer || root_path
  end

  def page_params
    params.require(:page).permit(:id)
  end
end
