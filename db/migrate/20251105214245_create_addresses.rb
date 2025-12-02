class CreateAddresses < ActiveRecord::Migration[7.2]
  def change
    create_table :addresses do |t|
      t.string :street
      t.string :description
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
