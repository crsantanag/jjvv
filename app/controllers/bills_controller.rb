class BillsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  before_action :set_bill, only: %i[ show edit update destroy ]

  def import
    if params[:file].blank?
      flash[:alert] = "DEBE SELECCIONAR UN ARCHIVO"
      redirect_to bills_path
      return
    end

    importer = ImportBillsFromExcel.new(params[:file])
    importer.call

    if importer.errors.any?
      flash[:alert] = "#{importer.failed.count} REGISTROS NO IMPORTADOS"
      flash[:import_errors] = importer.errors
    else
      flash[:notice] = "IMPORTACIÓN COMPLETADA EXITOSAMENTE"
    end
    redirect_to bills_path
  end

  # GET /bills or /bills.json
  def index
    # Año ya lo tengo definido
    year = selected_year

    from_month = params[:from_month].to_i
    to_month = params[:to_month].to_i

    from_month = 1 unless (1..12).include?(from_month)
    to_month = 12 unless (1..12).include?(to_month)

    @from_date = Date.new(year, from_month, 1)
    @to_date = Date.new(year, to_month, -1) # último día del mes

    # @bills = current_user.bills.where(date: @from_date..@to_date).order(date: :asc)
    @bills = Bill.where(date: @from_date..@to_date).order(date: :asc, created_at: :asc)

    @grouping = params[:grouping] ||= "by_month"

    case params[:grouping]
    when "by_month"
      @bills_by_month = @bills.group_by { |b| b.date.beginning_of_month }
    else # by_type
      orden_tipo_egreso = {
        "egreso_remuneracion" => 1,
        "egreso_util_aseo"    => 2,
        "egreso_gasto_basico" => 3,
        "egreso_mantencion"   => 4,
        "egreso_otro"         => 5
      }
      @bills_by_month = @bills.group_by(&:tipo_egreso).sort_by { |tipo, _| orden_tipo_egreso[tipo] || 99 }
    end

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Egresos",
               template: "bills/index",
               encoding: "UTF-8",
               layout: "pdf",
               orientation: "Portrait",
               page_size: "Letter"
      end
    end
  end

  # GET /bills/1 or /bills/1.json
  def show
  end

  # GET /bills/new
  def new
    @bill = current_user.bills.new
    @bill.date ||= Date.today # Asigna la fecha de hoy
  end

  # GET /bills/1/edit
  def edit
  end

  # POST /bills or /bills.json
  def create
    @bill = current_user.bills.new(bill_params)
    @bill.user_id = current_user.id

    respond_to do |format|
      if @bill.save
        flash[:notice] = "EGRESO REGISTRADO"
        format.html { redirect_to filtered_redirect }
        format.json { render :show, status: :created, location: @bill }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @bill.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bills/1 or /bills/1.json
  def update
    respond_to do |format|
      if @bill.update(bill_params)
        flash[:notice] = "EGRESO ACTUALIZADO"
        format.html { redirect_to filtered_redirect }
        format.json { render :show, status: :ok, location: @bill }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @bill.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bills/1 or /bills/1.json
  def destroy
    @bill.destroy!
    flash[:notice] = "EGRESO ELIMINADO"
    respond_to do |format|
      format.html { redirect_to filtered_redirect, status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bill
      # @bill = current_user.bills.find(params[:id])
      @bill = Bill.find(params[:id])
    end

    def filtered_redirect
      allowed_params = %i[from_month to_month grouping]
      filtered = params.slice(*allowed_params).to_unsafe_h.compact_blank
      bills_path(filtered)
    end

    # Only allow a list of trusted parameters through.
    def bill_params
      params.require(:bill).permit(:date, :tipo_egreso, :comment, :amount, :user_id)
    end
end
