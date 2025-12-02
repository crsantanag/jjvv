class ApartmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_apartment, only: %i[ show edit update destroy ]
  before_action :set_addresses, only: [ :new, :create, :edit, :update ]

  require "csv"

  def import
    if params[:file].blank?
      flash[:alert] = "DEBE SELECCIONAR UN ARCHIVO"
      redirect_to apartments_path
      return
    end

    importer = ImportApartmentsFromExcel.new(params[:file], current_user)
    importer.call

    if importer.errors.any?
      flash[:alert] = "#{importer.failed.count} REGISTROS NO IMPORTADOS"
      flash[:import_errors] = importer.errors
    else
      flash[:notice] = "IMPORTACIÓN COMPLETADA EXITOSAMENTE"
    end

    redirect_to apartments_path
  end

  # GET /apartments
  # muestra SOLO el formulario de búsqueda
  def index
    # dejamos los parámetros en variables para prerellenar el form si vienen
    @order = params[:order] || "number"
    @search = params[:search]
  end

  # GET /apartments/results
  # muestra SOLO los resultados de la búsqueda (tabla) y soporta CSV
  def results
    # decidir orden por parámetros
    search = params[:search]

    # Base query
    @apartments = Apartment.all

    # Aplicar búsqueda
    if search.present?
      @apartments = @apartments.where(
        "description ILIKE :q OR CAST(number AS text) ILIKE :q",
        q: "%#{search}%"
      )
    end

    if params[:order] == "description"
      @apartments = @apartments.order(description: :asc, number: :asc)
    else
      @apartments = @apartments.order(number: :asc, description: :asc)
    end

    respond_to do |format|
      format.html

      format.csv do
      filename = "apartments_#{Date.today}.csv"

      # materializar la colección filtrada (preserva order) e incluir address
      apartments_ordered = @apartments.includes(:address).to_a
      apartment_ids = apartments_ordered.map(&:id)

        # consulta robusta por apartment: suma tipo 1,2,3 y total
        rows = Deposit.where(apartment_id: apartment_ids)
                    .group(:apartment_id)
                    .pluck(
                      Arel.sql("apartment_id"),
                      Arel.sql("COALESCE(SUM(CASE WHEN CAST(tipo_ingreso AS text) = '1' THEN amount ELSE 0 END),0)"),
                      Arel.sql("COALESCE(SUM(CASE WHEN CAST(tipo_ingreso AS text) = '2' THEN amount ELSE 0 END),0)"),
                      Arel.sql("COALESCE(SUM(CASE WHEN CAST(tipo_ingreso AS text) = '3' THEN amount ELSE 0 END),0)"),
                      Arel.sql("COALESCE(SUM(amount),0)")
              )

        deposit_sums_by_apartment = rows.each_with_object({}) do |(apt_id, s1, s2, s3, tot), h|
          h[apt_id.to_i] = { suma1: s1.to_i, suma2: s2.to_i, suma3: s3.to_i, total: tot.to_i }
        end

        csv_string = CSV.generate(col_sep: ";") do |csv|
          csv << [ "Número", "Nombre", "Ap_paterno", "Ap_materno", "Description", "Street", "Tipo 1", "Tipo 2", "Tipo 3", "Total" ]

          apartments_ordered.each do |apt|
            sums = deposit_sums_by_apartment[apt.id] || { suma1: 0, suma2: 0, suma3: 0, total: 0 }
            csv << [
              apt.number,
              apt.nombre.to_s,
              apt.ap_paterno.to_s,
              apt.ap_materno.to_s,
              apt.description.to_s,
              apt.address&.street.to_s,
              sums[:suma1],
              sums[:suma2],
              sums[:suma3],
              sums[:total]
            ]
          end
        end

        # BOM para Excel y forzar Content-Length para que el navegador muestre progreso correcto
        csv_string = "\uFEFF" + csv_string
        response.headers["Content-Length"] = csv_string.bytesize.to_s

        send_data csv_string,
                filename: filename,
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
      end
    end
  end

  # GET /apartments/1 or /apartments/1.json
  def show
    @addresses  = Address.order(:street)
    @apartment  = Apartment.find(params[:id])
    @deposits   = @apartment.deposits.order(date: :asc, created_at: :asc)

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Historial_ingresos_#{@apartment.number}",
               template: "apartments/show",
               layout: "pdf",       # Asegúrate de tener app/views/layouts/pdf.html.erb
               page_size: "Letter",
               orientation: "Portrait",
               encoding: "UTF-8"
      end
    end
  end

  # GET /apartments/new
  def new
    # @apartments = current_user.apartments.order(:number)
    # @apartment = current_user.apartments.new

    @addresses  = Address.order(:street)
    @apartments = Apartment.order(:number)
    @apartment  = Apartment.new
  end

  # GET /apartments/1/edit
  def edit
    @addresses  = Address.order(:street)
  end

  # POST /apartments or /apartments.json
  def create
    @apartment = Apartment.new(apartment_params)
    @apartment.user_id = current_user.id

    respond_to do |format|
      if @apartment.save
        flash[:notice] = "#{current_user.type_community.upcase} CREAD#{current_user.type_community.upcase[-1]}"
        format.html { redirect_to filtered_redirect }
        format.json { render :show, status: :created, location: @apartment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @apartment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /apartments/1 or /apartments/1.json
  def update
    respond_to do |format|
      if @apartment.update(apartment_params)
        flash[:notice] = "#{current_user.type_community.upcase} ACTUALIZAD#{current_user.type_community.upcase[-1]}"
        format.html { redirect_to filtered_redirect }
        format.json { render :show, status: :ok, location: @apartment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @apartment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /apartments/1 or /apartments/1.json
  def destroy
    @apartment.destroy!

    respond_to do |format|
      flash[:notice] = "#{current_user.type_community.upcase} ELIMINAD#{current_user.type_community.upcase[-1]}"
      format.html { redirect_to filtered_redirect, status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def filtered_redirect
      allowed_params = %i[order commit]
      filtered = params.slice(*allowed_params).to_unsafe_h.compact_blank
      apartments_path(filtered)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_apartment
      # @apartment = current_user.apartments.find(params[:id])
      @apartment = Apartment.find(params[:id])
    end

    def set_addresses
      @addresses = Address.order(:street)
    end

    # Only allow a list of trusted parameters through.
    def apartment_params
      params.require(:apartment).permit(:number, :description, :start_date, :ult_mes_pago, :ult_ano_pago, :user_id, :address_id)
    end
end
