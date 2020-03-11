class V4::CheckoutsController < V4ApplicationController
   def renew_all
      begin
         resp = V4::Checkout.renew_all(user_params[:computing_id])
         Rails.logger.info("RenewAll results: #{resp.to_json}")
         render json: resp, status: :ok
      rescue Exception => e
         render plain: e.message, status: :bad_request
      end
   end

   def renew
      begin
         resp = V4::Checkout.renew(user_params[:computing_id], user_params[:item_barcode])
         Rails.logger.info("Renew results: #{resp.to_json}")
         render json: resp, status: :ok
      rescue Exception => e
         render plain: e.message, status: :bad_request
      end
   end

   private
   def user_params
      params.permit(:computing_id, :item_barcode, :format)
   end
 end
