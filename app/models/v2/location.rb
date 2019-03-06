class V2::Location < SirsiBase
  base_uri env_credential(:sirsi_web_services_base)

  LOCATION_PARAMS = {key: '*', includeFields: '*'}


  def all
    @@locations ||= get_locations
  end

  def find id
  end

 private
 def get_locations
   locations = self.class.get('/v1/policy/location/simpleQuery',
                              query: LOCATION_PARAMS,
                              headers: auth_headers
                             )
   if locations.present?
     puts 'loaded locations'
     locations.map! {|l| l['fields']}
   else
     []
   end
 end
end
