class V1::ItemsController < ApplicationController
  def show
    item = V1::Item.new(item_params)
    render xml: item.to_xml
  end

  private
  def item_params
    params.require(:id)
  end
end
