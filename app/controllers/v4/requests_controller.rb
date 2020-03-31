class V4::RequestsController < V4ApplicationController

  def hold
    hold = V4::Request::Type::Hold.new hold_params
    render json: hold, root: 'hold', serializer: V4::HoldSerializer
  end

  private
  def hold_params
    params.require(:hold).permit :title_key, :barcode, :pickup_library, :user_id
  end
end
