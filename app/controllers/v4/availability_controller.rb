class V4::AvailabilityController < V4ApplicationController
  def show
   @item = V4::Availability.new(item_params[:id])
   if @item.present? == false
     render plain: "Item #{item_params[:id]} is not found", status: :not_found
   else
     render json: @item
   end
  end

  private
  def item_params
    params.permit(:id, :format)
  end
end
