class DepositsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  before_action :set_deposit, only: %i[ show edit update destroy ]

  def index
    # valores por defecto para selects (puedes reutilizar los helpers que ya tenías)
    @from_date = Date.new(selected_year, 1, 1)
    @to_date   = Date.new(selected_year, 12, -1)
    # No cargamos @deposits aquí (evitamos consultas pesadas)
  end

  def import
    if params[:file].blank?
      flash[:alert] = "DEBE SELECCIONAR UN ARCHIVO"
      redirect_to deposits_path
      return
    end

    importer = ImportDepositsFromExcel.new(params[:file], current_user)
    importer.call

    if importer.errors.any?
      flash[:alert] = "#{importer.failed.count} REGISTROS NO IMPORTADOS"
      flash[:import_errors] = importer.errors
    else
      flash[:notice] = "IMPORTACIÓN COMPLETADA EXITOSAMENTE"
    end

    redirect_to deposits_path
  end

  def results
    # extraer parámetros y sanitizar
    year = selected_year

    from_month = params[:from_month].to_i
    to_month   = params[:to_month].to_i

    from_month = 1 unless (1..12).include?(from_month)
    to_month   = 12 unless (1..12).include?(to_month)

    @from_date = Date.new(year, from_month, 1)
    @to_date   = Date.new(year, to_month, -1)

    @apartment_number = params[:apartment_number].presence
    @apartment_description = params[:apartment_description].presence

    # grouping = params[:grouping] || "by_apartment_date"

    # scope base para mostrar y para las agregaciones que uses en PDF/CSV
    deposits_scope = current_user.deposits.joins(:apartment).where(date: @from_date..@to_date)
    base_scope = current_user.deposits.joins(:apartment).where(ano: year, mes: from_month..to_month)

    # aplicar filtros por departamento (número o descripción)
    if @apartment_number
      deposits_scope = deposits_scope.where(apartments: { number: @apartment_number })
      base_scope     = base_scope.where(apartments: { number: @apartment_number })
    elsif @apartment_description
      deposits_scope = deposits_scope.where("apartments.description ILIKE ?", "%#{@apartment_description}%")
      base_scope     = base_scope.where("apartments.description ILIKE ?", "%#{@apartment_description}%")
    end

    # ordenar y preparar variables de instancia que usa la vista
    @deposits = deposits_scope.order(:date, :created_at)
    @deposits_by_ano_mes = base_scope.order("apartments.number ASC, deposits.date ASC, deposits.created_at ASC, deposits.tipo_ingreso ASC")
    @deposits_by_month   = base_scope.order("deposits.mes ASC, apartments.number ASC, deposits.date ASC, deposits.created_at ASC")

    respond_to do |format|
      format.html # render results.html.erb (o puedes render :index pero con variables)
      format.pdf do
        render pdf: "Ingresos",
               template: "deposits/index",   # si tu pdf usa la misma vista ERB (cuidado con referencias)
               encoding: "UTF-8",
               layout: "pdf",
               orientation: "Portrait",
               page_size: "Letter"
      end
      # si quieres CSV aquí, añade format.csv { ... }
    end
  end


  # GET /deposits or /deposits.json
  def search
    year = selected_year

    from_month = params[:from_month].to_i
    to_month   = params[:to_month].to_i

    from_month =  1 unless (1..12).include?(from_month)
    to_month   = 12 unless (1..12).include?(to_month)

    @from_date = Date.new(year, from_month, 1)
    @to_date   = Date.new(year, to_month, -1)

    apartment_number = params[:apartment_number].presence
    apartment_description = params[:apartment_description].presence

    deposits_scope = current_user.deposits.joins(:apartment).where(date: @from_date..@to_date)

    if apartment_number
      deposits_scope = deposits_scope.where(apartments: { number: apartment_number })
    elsif apartment_description
      deposits_scope = deposits_scope.where("apartments.description ILIKE ?", "%#{apartment_description}%")
    end

    @deposits = deposits_scope.order(:date, created_at: :asc)

    base_scope = current_user.deposits.joins(:apartment).where(ano: year, mes: from_month..to_month)

    if apartment_number
      base_scope = base_scope.where(apartments: { number: apartment_number })
    elsif apartment_description
      base_scope = base_scope.where("apartments.description ILIKE ?", "%#{apartment_description}%")
    end

    @deposits_by_ano_mes = base_scope.order("apartments.number ASC, deposits.date ASC, deposits.tipo_ingreso ASC, created_at ASC")
    @deposits_by_month = base_scope.order("deposits.mes ASC, apartments.number ASC, deposits.date ASC")

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Ingresos",
               template: "deposits/index",
               encoding: "UTF-8",
               layout: "pdf",
              orientation: "Portrait",
              page_size: "Letter"
      end
    end
  end


  # GET /deposits/1 or /deposits/1.json
  def show
  end

  # GET /deposits/new
  def new
    @apartments = current_user.apartments.order(:number)
    @deposit = current_user.deposits.new
    @deposit.date ||= Date.today # Asigna la fecha de hoy
    # @deposit.apartment_number = nil # o prellenar si tienes alguna lógica (me lo indica ChatGPT al modificar la indexación)
  end

  # GET /deposits/1/edit
  def edit
    # OJO: Si edita la cantidad se debe recalcular todo hacia adelante.
    @apartments = current_user.apartments.order(:number)
    @deposit = current_user.deposits.find(params[:id])
    # @deposit.apartment_number = @deposit.apartment&.number
  end

  # POST /deposits or /deposits.json
  def create
    # OJO: Calcular meses pagados.
    @apartments = current_user.apartments.order(:number)
    @deposit = current_user.deposits.new(deposit_params)
    @deposit.user_id = current_user.id

    if @deposit.tipo_ingreso != "ingreso_comun"
      # Aquí debo hacer el cálculo de los meses que paga desde el último mes pagado. Antes agregar último mes pagado.
      @deposit.mes = @deposit.date.month
      @deposit.ano = @deposit.date.year
    end

    respond_to do |format|
      if @deposit.save
        flash[:notice] = "INGRESO REGISTRADO"
        format.html { redirect_to filtered_redirect  }
        format.json { render :show, status: :created, location: @deposit }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @deposit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deposits/1 or /deposits/1.json
  def update
    @deposit.assign_attributes(deposit_params)

    if @deposit.tipo_ingreso != "ingreso_comun"
       @deposit.mes = @deposit.date.month
       @deposit.ano = @deposit.date.year
    end

    respond_to do |format|
      if @deposit.save
        flash[:notice] = "INGRESO ACTUALIZADO"
        format.html { redirect_to filtered_redirect }
        format.json { render :show, status: :ok, location: @deposit }
      else
        @apartments = current_user.apartments
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @deposit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deposits/1 or /deposits/1.json
  def destroy
    @deposit.destroy!
    flash[:notice] = "INGRESO ELIMINADO"
    respond_to do |format|
      format.html { redirect_to filtered_redirect, status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deposit
      @deposit = current_user.deposits.find(params[:id])
    end

    def filtered_redirect
      allowed_params = %i[from_month to_month grouping]
      filtered = params.slice(*allowed_params).to_unsafe_h.compact_blank
      deposits_path(filtered)
    end

    # Only allow a list of trusted parameters through.
    def deposit_params
      params.require(:deposit).permit(:date, :amount, :comment, :tipo_ingreso, :mes, :ano, :user_id, :apartment_id) # Saqué de acá el parámetro apartment_id en los params, ya que lo asigno por el before_validation dentro del modelo.
    end
end
