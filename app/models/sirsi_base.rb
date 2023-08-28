class SirsiBase
  # TODO: add caching https://www.codementor.io/ruby-on-rails/tutorial/how-to-build-a-robust-json-api-client-with-ruby-httparty
  require 'benchmark'

  include HTTParty
  logger Rails.logger, :info
  base_uri env_credential(:sirsi_web_services_base)

  format :json

  default_timeout 10

  # Class variables to share among threads
  @@session_token = nil
  @@sirsi_user = nil
  @@staffKey = nil
  @@session_token = nil
  @@session_time = nil
  @@base_headers = nil
  @@auth_headers = nil

  # wrap api calls with this (we add the no_instrument attribute so we can filter certain responses from the log)
  #
  def self.ensure_login( no_instrument = false )
    response = nil
    begin
      if @@session_token.nil? || old_session?
        login
      end

      time = Benchmark.realtime do
        response = yield
      end
      Rails.logger.info "Sirsi Response: #{(time * 1000).round} mS" unless no_instrument
      return response

    rescue => e
      # login failed?
      if e.message.starts_with? 'retrying'
        Rails.logger.warn "Retrying"
        return yield
      end

      uri = response.present? ? response.uri : env_credential(:sirsi_web_services_base)
      Rails.logger.error "ERROR: #{uri} #{e.message} #{e.backtrace.first}"
      return {error: e.message}
    end
  end

  def self.login
    begin
      Rails.logger.info 'Sirsi logging in'
      login_body = {'login' => env_credential(:sirsi_user),
               'password' => env_credential(:sirsi_password)
              }
      time = Benchmark.realtime do
        @@sirsi_user = post( "/user/staff/login",
                            body: login_body.to_json,
                            headers: base_headers.without('x-sirs-sessionToken') )
      end
      raise if !@@sirsi_user.success?
      Rails.logger.info "Sirsi Response: #{(time * 1000).round} mS"

      @@staffKey = @@sirsi_user['staffKey']
      @@session_token = @@sirsi_user['sessionToken']
      @@session_time = Time.now
    rescue => e
      if @@sirsi_user.present?
        Rails.logger.error "Sirsi API Login Failed - #{e.class} - #{@@sirsi_user.request.uri} #{@@sirsi_user.body}"
      else
        Rails.logger.error "Sirsi API Login Failed - #{env_credential(:sirsi_web_services_base)} "
      end
      # reset the session token to force another login after this error
      @@session_token = nil
      raise
    end
  end

  def self.base_headers
    @@base_headers ||= {'x-sirs-clientID' => env_credential(:sirsi_client_id),
    'Content-Type' => 'application/json',
    'Accept' => 'application/json',
    'SD-Originating-App-Id' => 'Virgo',
    'SD-Preferred-Role' => 'STAFF'
    }
  end

  def self.auth_headers
    if @@session_token.present?
      @@auth_headers = base_headers.merge({'x-sirs-sessionToken' => @@session_token})
    end
  end

  def self.check_session response
    # Timeouts return a 200 code...
    error_code = response.dig('faultResponse', 'code') || '' rescue ''

    if response.code == 401 || error_code.include?('TimedOut')
      login
      raise "retrying: Sirsi request failed for #{response.request.uri} #{response.body}"
    end
  end

  def self.old_session?
    @@session_time.present? && (@@session_time < 1.hour.ago)
  end

  # used for healthcheck.
  def self.account_info
    # dont want to log response times for heartbeats
    ensure_login( no_instrument = true ) do
      response = get("/user/staff/key/#{@@staffKey}", headers: auth_headers, timeout: 5, max_retries: 0)
      check_session(response)
      return response
    end
  end

end
