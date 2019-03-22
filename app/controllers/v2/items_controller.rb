class V2::ItemsController < V2ApplicationController
  def show
   @item = V2::Item.find(item_params[:id])
   if @item.present?
     render
   else
     render :not_found
   end
  end

  private
  def item_params
    params.permit(:id)
  end
end
