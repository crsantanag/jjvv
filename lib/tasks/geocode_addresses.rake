namespace :geocode do
  desc "Geocodifica todas las direcciones que no tengan lat/lng"
  task addresses: :environment do
    require "geocoder"
    addresses = Address.where(latitude: nil).or(Address.where(longitude: nil))
    puts "Direcciones a geocodificar: #{addresses.count}"

    addresses.find_each(batch_size: 200).with_index do |addr, idx|
      begin
        # opcional: normalizar street
        addr.street = addr.street.to_s.strip
        addr.geocode
        if addr.latitude.present? && addr.longitude.present?
          addr.save!(validate: false)
          puts "#{idx + 1} ✓ id=#{addr.id} => #{addr.latitude},#{addr.longitude} (#{addr.street.truncate(60)})"
        else
          puts "#{idx + 1} ✗ id=#{addr.id} no geocode: #{addr.street.inspect}"
        end
      rescue => e
        puts "#{idx + 1} ERROR id=#{addr.id} => #{e.class}: #{e.message}"
      end
      # pequeño sleep para no saturar la API si usas un servicio con límites
      sleep 0.1
    end

    puts "FIN - geocoding"
  end
end
