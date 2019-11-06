class V2::UserLDAP < V2
  include HTTParty
  base_uri env_credential(:userinfo_url)
  default_timeout 15


  def self.find user_id
    response = get("/user/#{user_id}",
                   query: {auth: env_credential(:service_api_key)})

    if response.success?
      return response['user']
    else
      Rails.logger.error "Failed Userinfo Request: #{response.request.uri} #{response.body}"
      return {}
    end

  end

  def self.healthcheck
    # auth is not necessary, but just in case...
    response = get("/healthcheck",
                   query: {auth: env_credential(:service_api_key)})

    response
  end
end
