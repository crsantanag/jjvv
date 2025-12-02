Geocoder.configure(
# :google => requires API key; default lookup is :nominatim if not specified
timeout: 10,
lookup: :google, # cambiar a :nominatim si no quieres API Key
api_key: ENV["GOOGLE_MAPS_GEOCODE_API_KEY"],
units: :km,
ip_lookup: :ipinfo_io
)
