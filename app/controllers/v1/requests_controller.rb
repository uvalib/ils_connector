class V1::RequestsController < V1ApplicationController
  def renew_all
    item = V1::Request.new(request_params)
    render xml: item.to_xml
  end

  def hold
  end

  private
  def request_params
    params.require(:computingId)
  end
end
