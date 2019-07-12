class V2::RequestsController < V2ApplicationController

  # POST /v2/request/renew_all
  def renew_all
    begin 
      renew_cnt = V2::Request.renew_all( params[:computingId] )
      render plain: "#{renew_cnt} items renewed", status: :ok
    rescue Exception => e  
      render plain: e.message, status: :bad_request
    end
  end

  def renew
    # params checkoutKey, computingId
    # checkoutKey is the catalog key without the u or pda prefix
    # NOTE this does not seem to be called by virgo. Just return an not implemented 
    render plain: "Single item renew is not implemented", status: :not_implemented
  end

  def hold
  end


end
