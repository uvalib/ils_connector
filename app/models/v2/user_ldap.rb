class V2::UserLDAP < V2
  include HTTParty
  base_uri env_credential(:userinfo_url)
  default_timeout 10

  def self.find user_id

    # depending on how we are configured, use the right auth token
    auth = env_credential(:auth_shared_secret).nil? ? env_credential(:service_api_key) : auth_token( env_credential(:auth_shared_secret))

    response = get("/user/#{user_id}",
                    query: {auth: auth})

    if response.success?
      return response['user']
    else
      Rails.logger.error "Failed Userinfo Request: #{response.request.uri} #{response.body}"
      return {}
    end

  end

  def self.healthcheck
    # auth is not necessary, but just in case...
    response = get("/healthcheck" )

    response
  end

  # create a time limited JWT for service authentication
  def self.auth_token( secret )

    # expire in 5 minutes
    exp = Time.now.to_i + 5 * 60

    # just a standard claim
    exp_payload = { exp: exp }

    return JWT.encode exp_payload, secret, 'HS256'

  end

end
