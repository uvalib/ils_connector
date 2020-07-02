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

  def fill_hold
    hold = V4::Request::Hold.fill_hold(params[:barcode], params[:override], request.headers['SirsiSessionToken'])
    render json: hold.to_json
  end

  def create_scan
    scan_options = hold_params.to_h.merge({
      type: :scan,
      user_id: jwt_user[:user_id],
      }).transform_keys {|k| k.underscore.to_sym}
    scan = V4::Request::Hold.new( scan_options )

    render json: scan, root: 'scan', serializer: V4::HoldSerializer
  rescue JWT::ExpiredSignature
    render json: {error: 'Session Expired'}, status: 401
  end

  private
  def hold_params
    params.permit :titleKey, :itemBarcode, :pickupLibrary, :userId, :illiadTN
  end
end
