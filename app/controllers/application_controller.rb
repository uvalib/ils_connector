class ApplicationController < ActionController::API
  include ActionController::MimeResponds


  def landing
    respond_to do |format|
      format.html {render plain: "ILS Connector is JSON only."}
      #format.json {render json: {message: "POST to /api_users/sign_in to log in."} }
    end
  end

end
