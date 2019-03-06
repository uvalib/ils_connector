class V1::ListsController < V1ApplicationController
  before_action :set_library, only: [:show, :update, :destroy]

  # GET /v1/list/libraries
  def libraries
    @libraries = V1::FirehoseLibrary.new

    render xml: @libraries.to_xml
  end



  private
  # Use callbacks to share common setup or constraints between actions.
  def set_library
    @v1_lebrary = V1::FirehoseLibrary.find(params[:id])
  end

end
