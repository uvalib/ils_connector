class V4::UsersController < V4ApplicationController
   def show
      user = V4::User.find(user_params[:id])
      if user.nil? 
         render plain: "#{user_params[:id]} not found", status: :not_found
      else
         render json: user.as_json
      end
   end

   def check_pin
      if V2::User.check_pin(user_params[:id], user_params['pin'])
         render plain: "valid", status: :ok 
      else 
         render plain: "invalid", status: :not_found 
      end
   end

   def checkouts 
      checkouts = V4::User.get_checkouts(user_params[:id])
      if checkouts.nil? 
         render plain: "#{user_params[:id]} not found", status: :not_found
      else
         render json: checkouts.to_json, status: :ok
      end
   end

   private
   def user_params
      params.permit(:id, :pin, :format)
   end
 end
 