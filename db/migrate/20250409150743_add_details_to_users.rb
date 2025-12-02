class AddDetailsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name_community, :string
    add_column :users, :type_community, :string
    add_column :users, :saldo_inicial,  :integer, default: 0
    add_column :users, :name,           :string
    add_column :users, :role, :integer, default: 0
  end
end
