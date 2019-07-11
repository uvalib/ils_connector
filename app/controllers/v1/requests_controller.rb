class V1::RequestsController < V1ApplicationController
  def renew_all
    item = V1::Request.new(request_params)
    out = item.to_xml
    Rails.logger.info "RENEW ALL RESPONSE: #{out}"
    render xml: out
  end

  def renew
  end

  def hold
  end

  private
  def request_params
    params.require(:computingId)
  end
end
