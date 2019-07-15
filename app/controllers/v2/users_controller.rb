class V2::UsersController < V2ApplicationController

  # holds, checkouts, and reserves all route to the show action

  def show
   @user = V2::User.find(user_params[:id])
   if @user.present?
     render
   else
     render plain: "User, #{user_params[:id]}, is not found", status: :not_found
   end
  end

  def check_pin
   @is_valid_pin = V2::User.check_pin(user_params[:id], user_params['pin'])
   render
  end


  private
  def user_params
    params.permit(:id, :pin)
  end

end
