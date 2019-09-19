class V4::ItemsController < V4ApplicationController
  def show
   @item = V4::Item.find(item_params[:id])
   if @item.present? == false
     render plain: "Item #{item_params[:id]} is not found", status: :not_found
   end
  end

  private
  def item_params
    params.permit(:id, :format)
  end
end
