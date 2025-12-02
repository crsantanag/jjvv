class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :selected_year, :selected_year?

  def authorize_request
    unless current_user.admin?
      flash[:alert] = "NO ESTÁ AUTORIZADO PARA REALIZAR ESTA ACCIÓN"
      redirect_to root_path
    end
  end

  protected

  def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :name_community, :type_community, :saldo_inicial, :name, :role ])
      devise_parameter_sanitizer.permit(:account_update, keys: [ :name_community, :type_community, :saldo_inicial, :name, :role ])
  end

  def after_sign_in_path_for(resource)
    # Sí o sí se asigna el año actual al inicio de sesión
    session[:selected_year] = Date.today.year
    session[:balance_inicial] = calcular_balance_inicial(resource, session[:selected_year])
    root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def selected_year
    session[:selected_year]
  end

  def selected_year?
    session[:selected_year].present?
  end

  def calcular_balance_inicial(user, year)
    fecha_corte = Date.new(year - 1, 12, 31)
    # ingresos = user.deposit.where("date <= ?", fecha_corte).sum(:amount)
    ingresos = Deposit.where("date <= ?", fecha_corte).sum(:amount)
    # egresos  = user.bills.where("date <= ?", fecha_corte).sum(:amount)
    egresos  = Bill.where("date <= ?", fecha_corte).sum(:amount)
    user.saldo_inicial + ingresos - egresos
  end

  def require_admin
    unless current_user&.admin?
        redirect_to root_path, alert: "ACCION NO AUTORIZADA"
    end
  end
end
