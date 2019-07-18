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

    attr_accessor :sirsi_connection

    def is_healthy?
      @sirsi_connection.healthy
    end
  end

  # # GET /healthcheck
  # # GET /healthcheck.json
  def index
    status = get_health_status( )
    response = make_response( status )
    render json: response, :status => response.is_healthy? ? 200 : 500
  end

  private

  def get_health_status
    status = {}

    # no database
    #connected = ActiveRecord::Base.connection_pool.with_connection { |con| con.active? }  rescue false
    #status[ :database ] = Health.new( connected, connected ? '' : 'Database connection error' )

    sirsi_response = SirsiBase.account_info
    health = if sirsi_response.code == 200
               Health.new(true, '')
             else
               Health.new(false, "Sirsi API Error: #{sirsi_response.code} - #{sirsi_response.body}")
             end
    status[:sirsi_connection] = health
    return( status )
  end

  def make_response( health_status )
    r = HealthCheckResponse.new
    r.sirsi_connection = health_status[ :sirsi_connection ]

    return( r )
  end

end
