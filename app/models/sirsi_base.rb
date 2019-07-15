class SirsiBase
  # TODO: add caching https://www.codementor.io/ruby-on-rails/tutorial/how-to-build-a-robust-json-api-client-with-ruby-httparty

  include HTTParty
  base_uri env_credential(:sirsi_web_services_base)

  format :json

  default_timeout 20

  # wrap api calls with this
  #
  def self.ensure_login
    begin
      if !defined?(@@session_token) || old_session?
        login
      end
      yield

    rescue => e
      # catch a stale login?
      if e.message == 'retry'
        puts 'Retrying API call'
        return yield
      end

      Rails.logger.error e
      return []
    end
  end

  def self.login
    puts 'Logging in'
    login_body = {'login' => env_credential(:sirsi_user),
             'password' => env_credential(:sirsi_password)
            }
    @@sirsi_user = get( "/rest/security/loginUser",
                       { query: login_body,
                         headers: base_headers
    })

    @@session_token = @@sirsi_user['sessionToken']
    @@session_time = Time.now
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

  def self.check_session response
    if response.code == 401
      puts 'Session timed out'
      login
      raise 'retry'
    end
  end

  def self.old_session?
    defined?(@@session_time) && (@@session_time < 1.hour.ago)
  end

end
