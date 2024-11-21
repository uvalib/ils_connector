class HealthcheckController < ApplicationController

  # the basic health status object
  class Health
    attr_accessor :healthy
    attr_accessor :message

    def initialize( status, message )
      @healthy = status
      @message = message
    end

  end

  # the response
  class HealthCheckResponse

    attr_accessor :sirsi_connection, :user_service, :pda_service

    def is_healthy?
      @sirsi_connection.healthy &&
      @user_service.healthy &&
      @pda_service.healthy
    end
  end

  # # GET /healthcheck
  # # GET /healthcheck.json
  def index
    response = make_response
    if response.is_healthy?
      render json: response, :status => 200
    else
      Rails.logger.error "Healthcheck Failure: #{response.to_json}"
      render json: response, :status => 200
    end
  end

  private

  def make_response
    r = HealthCheckResponse.new
    r.sirsi_connection = sirsi_health
    r.user_service = user_service_health
    r.pda_service = pda_service_health

    return( r )
  end

  def sirsi_health
    health = nil
    begin
      sirsi_response = SirsiBase.account_info
      if sirsi_response.present?
         health = if sirsi_response.try(:code) == 200
                    Health.new(true, '')
                  else
                    Health.new(false, "Sirsi API Error: #{env_credential(:sirsi_web_services_base)} - #{sirsi_response.try(:code)} - #{sirsi_response.try(:body) || sirsi_response.inspect}")
                  end
      else
        health = Health.new( false, "Error connecting to or authenticating with Sirsi" )
      end
    rescue => ex
      health = Health.new( false, "Error: #{ex.class} #{ex.backtrace.first}" )
    end
    health
  end

  def user_service_health
    health = nil
    begin
      health_response = V4::UserLDAP.healthcheck
      health = if health_response.code == 200
                 Health.new(true, '')
               else
                 Health.new(false, "User Service (LDAP) Error: #{env_credential(:userinfo_url)} - #{health_response.code} - #{health_response.body}")
               end

    rescue => ex
      health = Health.new( false, "User Service (LDAP) Error: #{env_credential(:userinfo_url)} - #{ex.class}" )
    end
    health
  end

  def pda_service_health
    health = nil
    begin
      health_response = HTTParty.get("#{env_credential(:pda_base_url)}/healthcheck", timeout: 2, max_retries: 0)
      health = if health_response.code == 200
                 Health.new(true, '')
               else
                 Health.new(false, "PDA Service Error: #{env_credential(:pda_base_url)} - #{health_response.code} - #{health_response.body}")
               end

    rescue => ex
      health = Health.new( false, "PDA Service Error: #{env_credential(:pda_base_url)} - #{ex.class}" )
    end
    health
  end

end
