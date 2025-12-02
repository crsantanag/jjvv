class AddPagosToAddresses < ActiveRecord::Migration[7.2]
  def change
    add_column :addresses, :fecha_inicio, :date
    add_column :addresses, :ult_mes_pagado, :integer
    add_column :addresses, :ult_ano_pagado, :integer
  end
end
