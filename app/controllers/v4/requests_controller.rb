class V4::RequestsController < V4ApplicationController

  def options
    options = V4::RequestOption.new(options_params)
    render json: options, serializer: V4::RequestOptionSerializer, root: 'request_options'
  end

  def hold
    hold = V4::Hold.new hold_params
    render json: hold, root: 'hold', serializer: V4::HoldSerializer
  end

  private
  def hold_params
    params.permit :title_key, :barcode, :pickup_library, :user_id
  end

  def options_params
    params.permit(:user_id, :title_key)
  end
end
