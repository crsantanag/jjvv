class AddLatitudeLongitudeToAddresses < ActiveRecord::Migration[7.2]
  def change
    add_column :addresses, :latitude, :float
    add_column :addresses, :longitude, :float
  end
end
