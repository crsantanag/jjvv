class AddApartmentToBills < ActiveRecord::Migration[7.2]
  def change
    add_reference :bills, :apartment, null: true, foreign_key: true
  end
end
