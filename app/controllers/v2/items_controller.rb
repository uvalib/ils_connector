class V2::ItemsController < V2ApplicationController
  def show
   @item = V2::Item.find(item_params[:id])
   if @item.present? == false
     render plain: "Item #{item_params[:id]} is not found", status: :not_found
     return
   end
  end

  private
  def item_params
    params.permit(:id, :format)
  end
end
