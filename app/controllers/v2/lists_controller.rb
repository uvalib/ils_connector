class V2::ListsController < V2ApplicationController

  # GET /v2/list/libraries
  def libraries
    @libraries = V2::Library.all
  end

  # GET /v2/list/locations
  def locations
    @locations = V2::Location.all
  end

end
