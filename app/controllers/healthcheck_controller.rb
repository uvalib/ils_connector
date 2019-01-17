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

    attr_accessor :database

    def is_healthy?
      database.healthy
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

    # check the database
    connected = ActiveRecord::Base.connection_pool.with_connection { |con| con.active? }  rescue false
    status[ :database ] = Health.new( connected, connected ? '' : 'Database connection error' )

    return( status )
  end

  def make_response( health_status )
    r = HealthCheckResponse.new
    r.database = health_status[ :database ]

    return( r )
  end

end
