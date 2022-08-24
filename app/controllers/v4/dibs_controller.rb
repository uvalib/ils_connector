class V4::DibsController < V4ApplicationController
  include JWTUser
  before_action :authorize_jwt
  before_action :authorize_dibs, only: [:checkout, :checkin]

  # Sets an item's home location to DIBS
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

  # Reverts the item back to it's original home location
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

  # Check out a DIBS item barcode to a user
  def checkout

    co = V4::Dibs.checkout(dibs_params)
    if co.try :success?
      render json: {}, status: :ok
    else
      render json: {errors: co['messageList'], params: dibs_params}, status: co['code'] || 500
    end
  end

  # Check in a DIBS item
  def checkin
    co = V4::Dibs.checkin(dibs_params)
    if co.try :success?
      render json: {}, status: :ok
    else
      render json: {errors: co['messageList'], params: dibs_params}, status: co['code'] || 500
    end
  end

  private
  def authorize_dibs
    if !Rails.env.development? && params[:user_id] != jwt_user[:user_id]
      render plain: 'Unauthorized', status: 401
    end
  end

  def dibs_params
    # duration in hours
    params[:duration] = params[:duration].to_i if params[:duration]

    params.permit(:barcode, :user_id, :duration)
  end
end
