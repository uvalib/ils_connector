class V1::LibrariesController < ApplicationController
  before_action :set_library, only: [:show, :update, :destroy]

  # GET /v1/libraries
  def index
    @libraries = V1::Library.all

    render json: @libraries
  end

  # GET /v1/libraries/1
  def show
    render json: @v1_library
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_library
    @v1_library = V1::Library.find(params[:id])
  end

end
