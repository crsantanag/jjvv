class AddFieldsToApartments < ActiveRecord::Migration[7.2]
  def change
    add_column :apartments, :ap_paterno, :string
    add_column :apartments, :ap_materno, :string
    add_column :apartments, :nombre, :string
    add_column :apartments, :edad, :integer
    add_column :apartments, :estado_civil, :string
    add_column :apartments, :profesion, :string
    add_column :apartments, :domicilio, :string
    add_column :apartments, :rut, :integer
    add_column :apartments, :dv, :string
    add_column :apartments, :telefono, :string
    add_column :apartments, :estado, :string
  end
end
