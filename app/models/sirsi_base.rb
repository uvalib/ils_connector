class SirsiBase
  # TODO: add caching https://www.codementor.io/ruby-on-rails/tutorial/how-to-build-a-robust-json-api-client-with-ruby-httparty
  require 'benchmark'

  include HTTParty
  logger Rails.logger, :info
  base_uri env_credential(:sirsi_web_services_base)

  format :json

  default_timeout 20

  # wrap api calls with this
  #
  def self.ensure_login
    response = nil
    begin
      if !defined?(@@session_token) || old_session?
        login
      end

      time = Benchmark.realtime do
        response = yield
      end
      Rails.logger.info "Sirsi Response: #{time * 1000}ms"
      return response

    rescue => e
      # login failed?
      if e.message == 'retry'
        Rails.logger.warn "Retrying #{response.uri}"
        return yield
      end

      uri = response.present? ? response.uri : env_credential(:sirsi_web_services_base)
      Rails.logger.error "#{uri} #{e.message}"
      return []
    end
  end

  def self.login
    begin
      Rails.logger.info 'Sirsi logging in'
      login_body = {'login' => env_credential(:sirsi_user),
               'password' => env_credential(:sirsi_password)
              }
      @@sirsi_user = post( "/user/staff/login",
                          body: login_body.to_json,
                          headers: base_headers )
      raise if !@@sirsi_user.success?

      @@staffKey = @@sirsi_user['staffKey']
      @@session_token = @@sirsi_user['sessionToken']
      @@session_time = Time.now
    rescue => e
      if @@sirsi_user.present?
        Rails.logger.error "Sirsi API Login Failed - #{@@sirsi_user.request.uri} #{@@sirsi_user.body}"
      else
        Rails.logger.error "Sirsi API Login Failed - #{env_credential(:sirsi_web_services_base)} "
      end
      raise
    end
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
      Rails.logger.info "Sirsi request failed for #{response.request.uri} #{response.body}"
      login
      raise 'retry'
    end
  end

  def self.old_session?
    defined?(@@session_time) && (@@session_time < 1.hour.ago)
  end

  # used for healthcheck.
  def self.account_info
    ensure_login do
      get("/user/staff/key/#{@@staffKey}", headers: auth_headers)
    end
  end

end
