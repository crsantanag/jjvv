json.extract! deposit, :id, :date, :amount, :comment, :tipo_ingreso, :mes, :ano, :user_id, :apartment_id, :created_at, :updated_at
json.url deposit_url(deposit, format: :json)
