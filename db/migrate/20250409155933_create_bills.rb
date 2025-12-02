class CreateBills < ActiveRecord::Migration[7.2]
  def change
    create_table :bills do |t|
      t.date :date
      t.integer :tipo_egreso
      t.string :comment
      t.integer :amount, default: 0

      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
