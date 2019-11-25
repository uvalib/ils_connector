class V4::RequestsController < V4ApplicationController
   def renew_all
      begin
         cnt = V4::Request.renew_all(user_params[:computing_id])
         render plain: "#{cnt} items renewed", status: :ok
      rescue Exception => e
         render plain: e.message, status: :bad_request
      end 
   end

   def renew
      begin
         cnt = V4::Request.renew(user_params[:computing_id], user_params[:item_barcode])
         render plain: "#{cnt} items renewed", status: :ok
      rescue Exception => e
         render plain: e.message, status: :bad_request
      end 
   end

   private
   def user_params
      params.permit(:computing_id, :item_barcode, :format)
   end
 end
 