class V4::UsersController < V4ApplicationController
   require 'csv'
   def show
      user = V4::User.find(user_params[:id])
      if user.nil?
         render plain: "#{user_params[:id]} not found", status: :not_found
      else
         render json: user.as_json
      end
   end

   def check_pin
      ok, pin_ok = V4::User.check_pin(user_params[:id], user_params[:password])
      if !ok
         render plain: "Service unavailable", status: :service_unavailable
      elsif pin_ok
         render plain: "valid", status: :ok
      else
         render plain: "invalid", status: :unauthorized
      end
   end

   def change_pin
      ok, message = V4::User.change_password(user_params[:id], user_params[:current_pin], user_params[:new_pin])
      if ok
         render json: {}, status: :ok
      else
         render json: {message: message}, status: :unauthorized
      end
   end

   def change_password_with_token
      ok, message = V4::User.change_password_with_token(password_token_params)
      if ok
         render json: {}, status: :ok
      else
         render json: {message: message}, status: :unauthorized
      end
   end

   def forgot_password
      ok, message = V4::User.forgot_password(params[:userBarcode])
      if ok
         render json: {}, status: :ok
      else
         render json: {message: message}, status: :unauthorized
      end
   end

   def sirsi_staff_login
      user = V4::User.sirsi_staff_login(sirsi_login_params)
      if user.present?
         render json: user
      else
         render json: {error: "Invalid username or password."}, status: :unauthorized
      end
   end

   def checkouts
      ok, checkouts = V4::User.get_checkouts(user_params[:id])
      if !ok
         render plain: "Service unavailable", status: :service_unavailable
      elsif checkouts.nil?
         render plain: "#{user_params[:id]} not found", status: :not_found
      else
         respond_to do |format|
            format.json { render json: checkouts.to_json, status: :ok }
            format.csv {send_data list_to_csv(checkouts), filename: "checkouts_for_#{user_params['id']}_#{Date.today.to_s}.csv"}
         end
      end
   end

   def bills
      ok, bills = V4::User.get_bills(user_params[:id])
      if !ok
         render plain: "Service unavailable", status: :service_unavailable
      elsif bills.nil?
         render plain: "#{user_params[:id]} not found", status: :not_found
      else
         render json: bills.to_json, status: :ok
      end
   end

   def holds
      ok, holds = V4::User.get_holds(user_params[:id])
      if !ok
         render plain: "Service unavailable", status: :service_unavailable
      elsif holds.nil?
         render plain: "#{user_params[:id]} not found", status: :not_found
      else
         render json: holds.to_json, status: :ok
      end
   end

   private
   def user_params
      params.permit(:id, :pin, :format, :current_pin, :new_pin, :username, :password)
   end
   def password_token_params
      params.permit(:new_password, :reset_password_token)
   end
   def sirsi_login_params
      params.permit(:username, :password)
   end

   def list_to_csv list
      CSV.generate do |csv|
         csv << list.first.keys.map {|k| k.to_s.titleize}
         list.each do |item|
            csv << item.values
         end
      end
   end
 end
