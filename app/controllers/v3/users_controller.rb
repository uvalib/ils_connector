class V3::UsersController < V3ApplicationController
  #Copied from V1 for now

  def show
    user = V3::User.new(user_params)
    render xml: user.to_xml
  end

  def checkouts
    checkouts = V3::Checkout.new(user_params)
    render xml: checkouts.to_xml
  end

  def holds
    holds = V3::Hold.new(user_params)
    render xml: holds.to_xml
  end

  def reserves
    reserves = V3::Reserve.new(user_params)
    render xml: reserves.to_xml
  end


  private
  def user_params
    params.require(:id)
  end

end
