class AddPagosToApartments < ActiveRecord::Migration[7.2]
  def change
    add_column :apartments, :ult_mes_pagado, :integer
    add_column :apartments, :ult_ano_pagado, :integer
  end
end
