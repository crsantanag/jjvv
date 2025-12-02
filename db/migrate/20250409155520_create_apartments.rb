class CreateApartments < ActiveRecord::Migration[7.2]
  def change
    create_table :apartments do |t|
      t.integer :number
      t.string :description
      t.date :start_date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
