class V4::AvailabilityController < V4ApplicationController
  include JWTUser

  def show
    @item = V4::Availability.new(item_params[:id], jwt_user)

    # we return nil as an error
    if @item.data.nil?
       render plain: "Service unavailable", status: :service_unavailable
    elsif @item.data.empty?
       render plain: "Item #{item_params[:id]} is not found", status: :not_found
    else
       render json: @item
    end
  end

  def list
    @list = V4::AvailabilityList.new
    render json: @list
  end

  private
  def item_params
    params.permit(:id, :format)
  end
end
