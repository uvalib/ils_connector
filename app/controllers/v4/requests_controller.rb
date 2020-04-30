class V4::RequestsController < V4ApplicationController
  include JWTUser

  def create_hold
    hold_options = hold_params.to_h.merge({'user_id' => jwt_user[:user_id]}).transform_keys {|k| k.underscore.to_sym}
    hold = V4::Request::Hold.new( hold_options )
    render json: hold, root: 'hold', serializer: V4::HoldSerializer
  rescue JWT::ExpiredSignature
    render json: {error: 'Session Expired'}, status: 401
  end

  def delete_hold
    deleted = V4::Request::Hold.delete_hold(params[:id])
    render json: {status: deleted}
  end

  private
  def hold_params
    params.permit :titleKey, :itemBarcode, :pickupLibrary, :userId
  end
end
