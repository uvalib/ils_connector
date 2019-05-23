class SirsiBase
  # TODO: add caching https://www.codementor.io/ruby-on-rails/tutorial/how-to-build-a-robust-json-api-client-with-ruby-httparty

  include HTTParty
  base_uri env_credential(:sirsi_web_services_base)

  format :json

  default_timeout 1

  # wrap api calls with this
  #
  def self.ensure_login
    unless defined?(@@session_token)
      login
    end
    yield

  rescue => e
    # catch a stale login?
    # yield again to retry
    Rails.logger.error e
    return []
  end

  def self.login
    login_body = {'login' => env_credential(:sirsi_user),
             'password' => env_credential(:sirsi_password)
            }
    @@sirsi_user = get( "/rest/security/loginUser",
                       { query: login_body,
                         headers: base_headers
    })

    @@session_token = @@sirsi_user['sessionToken']
    @@session_date = @@sirsi_user['date']
  end

  def self.base_headers
    @@base_headers ||= {'x-sirs-clientID' => env_credential(:sirsi_client_id),
    'Content-Type' => 'application/json',
    'Accept' => 'application/json',
    'sd-originating-app-id' => 'cs'
    }
  end

  def self.auth_headers
    @@auth_headers = base_headers.merge({'x-sirs-sessionToken' => @@session_token})
  end

end
