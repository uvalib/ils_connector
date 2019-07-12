class V2::UsersController < V2ApplicationController

  # holds, checkouts, and reserves all route to show

  def show
   @user = V2::User.find(user_params[:id])
   if @user.present?
     render
   else
     render plain: "User, #{user_params[:id]}, is not found", status: :not_found
   end
  end


  private
  def user_params
    params.permit(:id)
  end

end
