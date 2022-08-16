class V4::DibsController < V4ApplicationController
  include JWTUser
  before_action :authorize_jwt

  def set_in_dibs
    Rails.logger.info( "Setting DIBS status for #{params[:barcode]}" )
    dib = V4::Dibs.set_in_dibs(params[:barcode])
    if dib.errors.none?
      render status: :ok
    elsif dib.errors.include? :not_found
      render status: :not_found
    else
      render json: {errors: dib.errors}, status: :unprocessable_entity
    end
  end

  def set_no_dibs
    Rails.logger.info( "Clearing DIBS status for #{params[:barcode]}" )
    dib = V4::Dibs.set_no_dibs(params[:barcode])
    if dib.errors.none?
      render status: :ok
    elsif dib.errors.include? :not_found
      render status: :not_found
    else
      render json: {errors: dib.errors}, status: :unprocessable_entity

    end
  end


  def checkout
    render json: {stub: true, barcode: params[:barcode], user_id: jwt_user[:user_id]}
  end

  def checkin
    render json: {stub: true, barcode: params[:barcode], user_id: jwt_user[:user_id]}
  end
end
