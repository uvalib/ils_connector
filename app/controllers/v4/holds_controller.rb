class V4::HoldsController < V4ApplicationController
  def create
    hold = V4::Hold.new hold_params
    render json: hold, root: 'hold'
  end

  private
  def hold_params
    params.permit :title_key, :barcode, :pickup_library, :user_id
  end
end
