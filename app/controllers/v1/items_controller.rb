class V1::ItemsController < V1ApplicationController
  def show
    item = V1::Item.new(item_params)
    render xml: item.to_xml
  end

  private
  def item_params
    params.require(:id)
  end
end
