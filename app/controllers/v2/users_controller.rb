class V2::UsersController < V2ApplicationController

  def show
    user = V2::User.new(user_params)
    render xml: user.to_xml
  end

  def checkouts
    checkouts = V2::Checkout.new(user_params)
    render xml: checkouts.to_xml
  end

  def holds
    holds = V2::Hold.new(user_params)
    render xml: holds.to_xml
  end

  def reserves
    reserves = V2::Reserve.new(user_params)
    render xml: reserves.to_xml
  end


  private
  def user_params
    params.require(:id)
  end

end
