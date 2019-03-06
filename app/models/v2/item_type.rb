class V2::ItemType < SirsiBase
  base_uri env_credential(:sirsi_web_services_base)

 REQUEST_PARAMS = {key: '*',
                   includeFields: '*'}


 def self.all
   @@items = get('/v1/policy/itemType/simpleQuery',
                 query: REQUEST_PARAMS,
                 headers: auth_headers
                )
   @@items = @@items.map do |i|
     i['fields'].merge 'key' => i['key']
   end
 end

 def self.find(key = 'policyNumber', value)
   unless defined?(@@items)
     all
   end

   @@items.find {|i| i[key] == value}

 end
end
