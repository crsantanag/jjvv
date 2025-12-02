json.extract! bill, :id, :date, :tipo_ingreso, :comment, :user_id, :created_at, :updated_at
json.url bill_url(bill, format: :json)
