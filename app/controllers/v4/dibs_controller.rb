class V4::DibsController < V4ApplicationController
  #include JWTUser

  def set_in_dibs
    Rails.logger.info( "Setting DIBS status for #{params[:barcode]}" )
    resp = V4::Dibs.set_in_dibs(params[:barcode])
    render json: resp, status: :ok
  rescue JWT::ExpiredSignature
    render json: {error: 'Session Expired'}, status: 401
  end

  def set_no_dibs
    Rails.logger.info( "Clearing DIBS status for #{params[:barcode]}" )
    resp = V4::Dibs.set_no_dibs(params[:barcode])
    render json: resp, status: :ok
  rescue JWT::ExpiredSignature
    render json: {error: 'Session Expired'}, status: 401
  end

  private

end
