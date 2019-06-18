class V1::ListsController < V1ApplicationController

  # GET /v1/list/libraries
  def libraries
    @libraries = V1::FirehoseLibrary.all

    render xml: @libraries
  end

  # GET /v1/list/locations
  def locations
    @locations = V1::Location.all

    render xml: @locations
  end

end
