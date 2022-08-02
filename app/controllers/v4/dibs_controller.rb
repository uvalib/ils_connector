class V4::DibsController < V4ApplicationController
  include JWTUser
  before_action :authorize_jwt

  def set_in_dibs
    Rails.logger.info( "Setting DIBS status for #{params[:barcode]}" )
    dib = V4::Dibs.set_in_dibs(params[:barcode])
    if dib.valid?
      render status: :ok
    elsif dib.errors[:not_found]
      render status: :not_found
    else
      render json: dib.errors, status: :unprocessable_entity
    end
  rescue JWT::ExpiredSignature
    render json: {error: 'Session Expired'}, status: 401
  end

  def set_no_dibs
    Rails.logger.info( "Clearing DIBS status for #{params[:barcode]}" )
    dib = V4::Dibs.set_no_dibs(params[:barcode])
    if dib.valid?
      render status: :ok
    elsif dib.errors[:not_found]
      render status: :not_found
    else
      render json: dib.errors, status: :unprocessable_entity

    end
  rescue JWT::ExpiredSignature
    render json: {error: 'Session Expired'}, status: 401
  end

  private

end
