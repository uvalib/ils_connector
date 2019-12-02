class V2::Location < SirsiBase
  include Refreshable
  base_uri env_credential(:sirsi_web_services_base)

  LOCATION_PARAMS = {key: '*', includeFields: '*'}

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
     locations = get('/policy/location/simpleQuery',
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
   reset_refresh_timer
   locations
 end


end
