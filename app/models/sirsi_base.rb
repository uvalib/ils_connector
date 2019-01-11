class SirsiBase
  # TODO: add caching https://www.codementor.io/ruby-on-rails/tutorial/how-to-build-a-robust-json-api-client-with-ruby-httparty

  include HTTParty
  base_uri env_credential(:sirsi_web_services_base)

  format :json

  def initialize
    login
  end

  def login
    login_body = {'login' => env_credential(:sirsi_user),
             'password' => env_credential(:sirsi_password)
            }
    @sirsi_user = self.class.get( "/rest/security/loginUser",
                                  { query: login_body,
                                    headers: login_headers
    })

    @session_token = @sirsi_user['sessionToken']
    @session_date = @sirsi_user['date']
  rescue e
    byebug
  end

  def base_headers
    @base_headers ||= {'x-sirs-clientID' => env_credential(:sirsi_client_id),
    'Content-Type' => 'application/json',
    'Accept' => 'application/json'
    }
  end

  def login_headers
     base_headers.merge({'sd-originating-app-id' => 'cs'})
   end

  def auth_headers
    @auth_headers = base_headers.merge({'x-sirs-sessionToken' => @session_token})
  end

end
