class V2::RequestsController < V2ApplicationController

  # POST /v2/request/renew_all
  def renew_all
    computing_id = params[:computingId]
    user_barcode = V2::Request.get_user_barcode(computing_id)
    if user_barcode.blank? 
      render plain: "User #{computing_id} not found", status: :bad_request
      return
    end

    begin 
      renew_cnt = V2::Request.renew_all( user_barcode )
      render plain: "#{renew_cnt} items renewed", status: :ok
    rescue Exception => e  
      render plain: e.message, status: :bad_request
    end
  end

  def renew
    # params checkoutKey, computingId
    # checkoutKey is the catalog key without the u or pda prefix
    computing_id = params[:computingId]
    user_barcode = V2::Request.get_user_barcode(computing_id)
    if user_barcode.blank? 
        render plain: "User #{computing_id} not found", status: :bad_request
        return
    end

    begin 
      render plain: V2::Request.renew_item(user_barcode, params[:checkoutKey])
    rescue Exception => e  
      render plain: e.message, status: :bad_request
    end
  end

  def hold
    # EX: Parameters: {"computingId"=>"lf6f", "catalogId"=>"2652375", "pickupLibraryId"=>"2", "callNumber"=>"F1411 .S697 1996 t.3"}
    # Lookup user barcode from computingID
    computing_id = params[:computingId]
    user_barcode = V2::Request.get_user_barcode(computing_id)
    if user_barcode.blank? 
      render plain: "User #{computing_id} not found", status: :bad_request
      return
    end

    # Lookup libray details based in policyID
    lib_policy_id = params[:libraryId]
    lib_detail = V2::Location.get_library(lib_policy_id)
    if lib_detail.blank? 
      render plain: "LibraryID #{lib_policy_id} not found", status: :bad_request
      return
    end

    # Find item from catalogID
    catalog_id = params[:catalogId]
    call_num = params[:callNumber]
    item = V2::Item.find(catalog_id)
    if lib_detail.blank? 
      render plain: "CatalogID #{catalog_id} not found", status: :bad_request
      return
    end

    # Find barcode from callnumber
    item_barcode = ""
    item["CallInfo"].each do |hold|
      if hold["callNumber"] == call_num 
        # found matching callnumber. Return barcode of first holdable copy
        hold["ItemInfo"].each do |cpy|
          next if V2::Item.is_copy_shadowed?(cpy)  

          curr_loc = V2::Location.find(cpy['currentLocationID'])
          next if curr_loc.blank?
          next if curr_loc['shadowed']

          if curr_loc['holdable'] && (cpy['chargeable'] || item['TitleAvailabilityInfo']["holdable"])
            item_barcode = cpy["itemID"]
            break
          end
        end
      end
    end
    if item_barcode.blank? 
      render plain: "Copy for #{call_num} not found", status: :bad_request
      return
    end

    render plain: V2::Request.hold_item(user_barcode, lib_detail["key"], item_barcode, call_num)
  end
end
