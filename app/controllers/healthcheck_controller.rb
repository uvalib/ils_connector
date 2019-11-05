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

    attr_accessor :sirsi_connection, :user_service

    def is_healthy?
      @sirsi_connection.healthy
      @user_service.healthy
    end
  end

  # # GET /healthcheck
  # # GET /healthcheck.json
  def index
    response = make_response
    render json: response, :status => response.is_healthy? ? 200 : 500
  end

  private

  def make_response
    r = HealthCheckResponse.new
    r.sirsi_connection = sirsi_health
    r.user_service = user_service_health

    return( r )
  end

  def sirsi_health
    health = nil
    begin
      sirsi_response = SirsiBase.account_info
      if sirsi_response != []
         health = if sirsi_response.code == 200
                    Health.new(true, '')
                  else
                    Health.new(false, "Sirsi API Error: #{sirsi_response.code} - #{sirsi_response.body}")
                  end
      else
        health = Health.new( false, "Error connecting to, or authenticating with Sirsi" )
      end
    rescue => ex
      health = Health.new( false, "Error: #{ex.class}" )
    end
  end

  def user_service_health
    health = nil
    begin
      health_response = V2::UserLDAP.healthcheck
      health = if health_response.code == 200
                 Health.new(true, '')
               else
                 Health.new(false, "User Service (LDAP) Error: #{env_credential(:userinfo_url)} - #{health_response.code} - #{health_response.body}")
               end

    rescue => ex
      health = Health.new( false, "Error: #{ex.class}" )
    end
    health
  end

end
