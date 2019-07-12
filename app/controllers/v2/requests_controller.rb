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
    begin 
      render xml: V2::Request.renew_item(params[:computingId], params[:checkoutKey])
    rescue Exception => e  
      render plain: e.message, status: :bad_request
    end
  end

  def hold
    # @FormParam("computingId")        String computingId,
    # @FormParam("catalogId") 	     String catalogId,
    # @FormParam("pickupLibraryId") 	 String libraryId,
    # @FormParam("callNumber")    	 String callNumber)
  end


end
