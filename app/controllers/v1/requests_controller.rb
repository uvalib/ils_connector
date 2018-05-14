class V1::RequestsController < ApplicationController
  def renew_all
    item = V1::Request.new(request_params)
    byebug
    render xml: item.to_xml
  end

  private
  def request_params
    params.require(:computingId)
  end
end
