class V2::ListsController < V2ApplicationController

  before_action :set_library, only: [:show, :update, :destroy]

  # GET /v2/list/libraries
  def libraries
    @libraries = V2::Library.all
  end



  private
  # Use callbacks to share common setup or constraints between actions.
  def set_library
    @library = V2::Library.find(params[:id])
  end


end
