class V2::UserLDAP < V2

  include HTTParty
  base_uri env_credential(:userinfo_url)


  def self.find user_id
    response = get("/user/#{user_id}",
                   query: {auth: env_credential(:service_api_key)})

    if response.success?
      return response['user']
    else
      raise "LDAP query failed: #{response.message}"
    end

  end



end
