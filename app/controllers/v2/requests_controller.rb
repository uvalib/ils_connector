class V2::RequestsController < V2ApplicationController

  # GET /v2/request/renew_all
  def renew_all
    @libraries = V2::Library.all
  end

  def renew
  end

  def hold
  end


end
