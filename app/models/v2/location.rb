class V2::Location < SirsiBase
  base_uri env_credential(:sirsi_web_services_base)

  LOCATION_PARAMS = {key: '*', includeFields: '*'}
  REFRESH_INTERVAL = 1.day
  REFRESH_TIME = '3am'
  REFRESH_ZONE = 'Eastern Time (US & Canada)'

  def self.all
    @@locations = nil if time_to_refresh?
    @@locations ||= get_locations
  end

  def self.find(name)
    V2::Location.all
    @@locations.find {|loc| loc['displayName'] == name }
  end


 private
 def self.get_locations
   locations = []
   ensure_login do
     locations = get('/v1/policy/location/simpleQuery',
                                query: LOCATION_PARAMS,
                                headers: auth_headers
                    )
     check_session(locations)
     if locations.present?
       locations = locations.parsed_response.map {|l| l['fields']}
     end
    #  locations.each do |l|
    #     if !(l['shadowed'] == false && (l['onShelf'] || !l['holdable']))
    #       puts "#{l['displayName']} UNAVAILABLE"
    #     end
    #  end
     locations
   end
   @@next_update = Time.parse(REFRESH_TIME).in_time_zone(REFRESH_ZONE) + REFRESH_INTERVAL
   Rails.logger.info "Loaded locations. Next update: #{@@next_update}"
   locations
 end

 def self.time_to_refresh?
   return true if !defined?(@@next_update)
   Time.current.in_time_zone(REFRESH_ZONE) >= @@next_update
 end

end
