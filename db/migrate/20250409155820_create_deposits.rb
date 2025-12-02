class CreateDeposits < ActiveRecord::Migration[7.2]
  def change
    create_table :deposits do |t|
      t.date :date
      t.integer :tipo_ingreso
      t.string :comment
      t.integer :amount, default: 0
      t.integer :mes
      t.integer :ano
      t.references :user, null: false, foreign_key: true
      t.references :apartment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
