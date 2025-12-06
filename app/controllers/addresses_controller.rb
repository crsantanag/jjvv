class AddressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_address, only: %i[ show edit update destroy ]

  def index
    @order = params[:order] || "street"
    @search = params[:search]
  end

  # GET /addresses/results
  # Ejecuta la búsqueda y muestra resultados; soporta CSV
  def results
    order_sql   = params[:order] == "description" ? "description ASC" : "street ASC"
    search      = params[:search].to_s.strip
    order_param = params[:order]

    # Empezar con la relación base (sin filtro)
    @addresses = Address.all

    # Aplicar búsqueda
    if search.present?
      @addresses = @addresses.where(
        "description ILIKE :q OR street ILIKE :q",
        q: "%#{search}%"
      )
    end

    # Aplicar orden una sola vez
    @addresses = @addresses.order(order_sql)

    respond_to do |format|
      format.html
      format.csv do
        filename = "addresses_#{Date.today}.csv"

        # materializar collection filtrada y ordenada
        addresses_ordered = @addresses.includes(:apartments).to_a
        address_ids = addresses_ordered.map(&:id)
        if address_ids.empty?
                csv_string = "\uFEFF" + CSV.generate_line([ "ID", "Street", "Description", "User ID", "Num Socios", "Ingreso (tipo 1)", "Certificados (tipo 2)", "Otros (tipo 3)", "Total por Dirección", "Created At" ], col_sep: ";")
          return send_data csv_string, filename: filename, type: "text/csv; charset=utf-8", disposition: "attachment"
        end

        # ---------------------------------------------------------
        # Query única que calcula suma por tipo (1,2,3) y total por address
        # usamos Arel.sql para marcar las expresiones SQL como seguras
        # ---------------------------------------------------------
        rows = Deposit.joins(:apartment)
                      .where(apartments: { address_id: address_ids })
                      .group(Arel.sql("apartments.address_id"))
                      .pluck(
                        Arel.sql("apartments.address_id"),
                        Arel.sql("COALESCE(SUM(CASE WHEN CAST(deposits.tipo_ingreso AS text) = '1' THEN deposits.amount ELSE 0 END),0) AS suma1"),
                        Arel.sql("COALESCE(SUM(CASE WHEN CAST(deposits.tipo_ingreso AS text) = '2' THEN deposits.amount ELSE 0 END),0) AS suma2"),
                        Arel.sql("COALESCE(SUM(CASE WHEN CAST(deposits.tipo_ingreso AS text) = '3' THEN deposits.amount ELSE 0 END),0) AS suma3"),
                        Arel.sql("COALESCE(SUM(deposits.amount),0) AS total")
                      )
        # rows => [[address_id, suma1, suma2, suma3, total], ...]

        sums_hash = rows.each_with_object({}) do |(addr_id, s1, s2, s3, tot), h|
          h[addr_id.to_i] = { suma1: s1.to_i, suma2: s2.to_i, suma3: s3.to_i, total: tot.to_i }
        end

        csv_string = CSV.generate(col_sep: ";") do |csv|
          csv << [
            "ID",
            "Street",
            "Description",
            "Num Socios",
            "Socios (lista)",
            "Cuotas sociales (tipo 1)",
            "Certificados (tipo 2)",
            "Otros (tipo 3)",
            "Total por Dirección"
          ]

          addresses_ordered.each do |address|
            sums = sums_hash[address.id] || { suma1: 0, suma2: 0, suma3: 0, total: 0 }

            # Preparar lista de socios: "DESCRIPCION (Nro 123)" separados por " | "
            socios_list = address.apartments.order(:number).map do |a|
              desc = a.description.to_s.strip
              num  = a.number.to_s
              "#{desc} (Nro #{num})"
            end.join(" | ")

            # Opcional: truncar la lista si es demasiado larga (evita celdas gigantes)
            socios_list = socios_list.length > 1000 ? socios_list[0, 1000] + " …" : socios_list

            csv << [
              address.id,
              address.street.to_s,
              address.description.to_s,
              address.apartments.size,
              socios_list,
              sums[:suma1],
              sums[:suma2],
              sums[:suma3],
              sums[:total]
            ]
          end

          # fila resumen al final (opcional)
          grand_total = sums_hash.values.sum { |h| h[:total] }
          csv << [ "", "", "", "", "", "", "", "Total general:", grand_total ]
        end

        # BOM para Excel
        csv_string = "\uFEFF" + csv_string

        # antes de enviar, forzamos Content-Length correcto
        response.headers["Content-Length"] = csv_string.bytesize.to_s

        # ahora enviamos

        send_data csv_string,
                  filename: filename,
                  type: "text/csv; charset=utf-8",
                  disposition: "attachment"
      end
    end
  end

  # GET /addresses/1 or /addresses/1.json
  def show
    @address = Address.includes(apartments: :deposits).find(params[:id])

    # Lista de apartments ordenada
    @apartments = @address.apartments.order(:number)

    # IDs de los apartments de la address
    apartment_ids = @apartments.pluck(:id)

    # Todas las deposits de esos apartments, agrupadas por apartment_id (para la vista HTML)
    @deposits_grouped = Deposit.where(apartment_id: apartment_ids)
                               .includes(:apartment)
                               .order(:date, :created_at)
                               .group_by(&:apartment_id)

    # Sumas por apartment (hash { apartment_id => suma })
    @sums_by_apartment = Deposit.where(apartment_id: apartment_ids).group(:apartment_id).sum(:amount)

    # Total general (opcional)
    @total_general = @sums_by_apartment.values.sum

    respond_to do |format|
      format.html

      format.pdf do
        # Para el PDF: lista plana de deposits pertenecientes a la address, en orden cronológico ascendente
        @deposits = Deposit.joins(:apartment)
                           .where(apartments: { address_id: @address.id })
                           .includes(:apartment)
                           .order(:date, :created_at)

        render pdf: "Historial_ingresos_x_dirección_#{@address.id}",
               template: "addresses/show",  # o "addresses/show.pdf.erb" si prefieres separar
               layout: "pdf",               # app/views/layouts/pdf.html.erb
               page_size: "Letter",
               orientation: "Portrait",
               encoding: "UTF-8",
               margin: { top: 15, bottom: 15, left: 10, right: 10 },
               disposition: "inline"
      end
    end
  end

  # GET /addresses/new
  def new
    @address = Address.new
  end

  # GET /addresses/1/edit
  def edit
  end

  # POST /addresses or /addresses.json
  def create
    @address = Address.new(address_params)
    @address.user_id = current_user.id

    respond_to do |format|
      if @address.save
        format.html { redirect_to @address, notice: "Address was successfully created." }
        format.json { render :show, status: :created, location: @address }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @address.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /addresses/1 or /addresses/1.json
  def update
    respond_to do |format|
      if @address.update(address_params)
        format.html { redirect_to @address, notice: "Address was successfully updated." }
        format.json { render :show, status: :ok, location: @address }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @address.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /addresses/1 or /addresses/1.json
  def destroy
    @address.destroy!

    respond_to do |format|
      format.html { redirect_to addresses_path, status: :see_other, notice: "Address was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_address
      @address = Address.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def address_params
      params.require(:address).permit(:street, :description, :fecha_inicio, :ult_mes_pagado, :ult_ano_pagado, :user_id)
    end
end
