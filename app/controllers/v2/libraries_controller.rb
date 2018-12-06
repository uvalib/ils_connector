class V2::LibrariesController < V2ApplicationController

  before_action :set_library, only: [:show, :update, :destroy]

  # GET /v2/libraries
  def index
    @libraries = V2::Library.all
  end

  # GET /v2/libraries/1
  def show
    render xml: @library
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_library
    @library = V2::Library.find(params[:id])
  end


end
