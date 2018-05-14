class V1::UsersController < ApplicationController

  def show
    user = V1::User.new(user_params)
    render xml: user.to_xml
  end

  def checkouts
    checkouts = V1::Checkout.new(user_params)
    render xml: checkouts.to_xml
  end

  def holds
    holds = V1::Hold.new(user_params)
    render xml: holds.to_xml
  end

  def reserves
    reserves = V1::Reserve.new(user_params)
    render xml: reserves.to_xml
  end


  private
  def user_params
    params.require(:id)
  end
end
