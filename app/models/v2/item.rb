class V2::Item < SirsiBase
  base_uri env_credential(:sirsi_web_services_base)
  default_timeout 5

  def self.find item_id
    old_find item_id

    # new_find uses Sirsi's newer api, requires nested calls and is too slow
    # new_find item_id
  end

  ## rest/standard/lookupTitleInfo?titleID=752166&includeItemInfo=true&includeCatalogingInfo=true
  #       &includeAvailabilityInfo=true&includeFields=*&includeShadowed=NONE
  OLD_REQUEST_PARAMS= { json: 'true', includeItemInfo: 'true', includeCatalogingInfo: 'true',
                        includeAvailabilityInfo: 'true', includeFields: '*', includeShadowed: 'BOTH'
  }

  def self.old_find item_id
    ensure_login do
      data = {}.with_indifferent_access
      response = get('/rest/standard/lookupTitleInfo',
                     query: OLD_REQUEST_PARAMS.merge(titleID: item_id),
                     headers: auth_headers
                    )
      check_session(response)
      if response['TitleInfo'].present? && response['TitleInfo'].one? &&
          response['TitleInfo'].first['titleControlNumber'].present?
        data = response['TitleInfo'].first
      else
        # not found
      end
      data
    end
  end

  def self.new_find item_id
    ensure_login do
      item = {}.with_indifferent_access
      item["titleID"] = item_id
      item["CallInfo"] = []
      response = get("/v1/catalog/bib/key/#{item_id}?includeFields=callList,*",
                     headers: auth_headers
                    )
      item["shadowed"] = response["fields"]["shadowed"]
      response["fields"]["callList"].each do |cl|
        key = cl["key"]
        call_resp = get("/v1/catalog/call/key/#{key}?includeFields=itemList,*",
                        headers: auth_headers
                       )
        holding = {}.with_indifferent_access
        holding["callNumber"] = call_resp["fields"]["dispCallNumber"]
        holding["shelvingKey"] = call_resp["fields"]["sortCallNumber"]
        holding["shadowed"] = call_resp["fields"]["shadowed"]
        holding["libraryID"] = call_resp["fields"]["library"]["key"]
        holding["ItemInfo"] = []

        call_resp["fields"]["itemList"].each do |holding_copy|
          copy_key = holding_copy["key"]
          copy_resp = get("/v1/catalog/item/key/#{copy_key}",
                          headers: auth_headers
                         )
          copy = {}.with_indifferent_access
          copy["itemID"] = copy_resp["fields"]["barcode"]
          copy["copyNumber"] = copy_resp["fields"]["copyNumber"]
          copy["itemTypeID"] = copy_resp["fields"]["itemType"]["key"]
          copy["shadowed"] = copy_resp["fields"]["shadowed"]
          copy["chargeable"] = copy_resp["fields"]["circulate"]
          copy["homeLocationID"] = copy_resp["fields"]["homeLocation"]["key"]
          copy["currentLocationID"] = copy_resp["fields"]["currentLocation"]["key"]
          holding["ItemInfo"] << copy
        end
        item["CallInfo"] << holding
      end
      item
    end
  end

  # If all copies are shadowed, the holding is shadowed
  def self.is_holding_shadowed?(holding)
    holding['ItemInfo'].each do |cpy|
      if is_copy_shadowed?(cpy) == false
        return false
      end
    end
    return true
  end

  # A copy is shadowed if it has no location, or its location is shadowed
  def self.is_copy_shadowed?(copy)
    if copy['currentLocationID'].blank? || copy['homeLocationID'].blank? 
      return true
    end
    curr_loc = V2::Location.find(copy['currentLocationID'])
    home_loc = V2::Location.find(copy['homeLocationID'])
    if copy['homeLocationID'] == "RSRVSHADOW"
      return curr_loc['shadowed']
    end
    return curr_loc["shadowed"]
  end

  def self.circulate?(title_availability, copy)
    if copy['chargeable']
      return "Y"
    end
    if title_availability[ 'holdable']
      return "M"
    end
    return "N"
  end

  #  Returns true only if there is an item can can be held, and if no copies are available.
  def self.is_holdable?(title_availability, holding)
    if is_holding_shadowed?(holding)
      Rails.logger.debug "Holding is not holdable because it is shadowed"
      return false
    end

    lib = V2::Library.find_by(code: holding['libraryID'])
    if lib.holdable == false
      return false
    end

    has_holdable_item = false
    has_available_item = false
    holding['ItemInfo'].each do |cpy|
      if is_copy_shadowed?(cpy)
        next
      end

      item_type = V2::ItemType.find("displayName", cpy['itemTypeID'])
      if item_type.blank?
        next
      end

      curr_loc = V2::Location.find(cpy['currentLocationID'])
      if curr_loc.blank?
        next
      end
      if curr_loc['shadowed']
        next
      end

      item_holdable =  V2::ItemType.holdable?( item_type['policyNumber'] )
      if curr_loc['holdable'] && item_holdable && circulate?(title_availability, cpy)
        has_holdable_item = true
      end
      if curr_loc['onShelf'] || !item_holdable
        has_available_item = true
      end
    end
    return has_holdable_item == true && has_available_item == false

  end

  def self.is_current_periodical?(copy)
    # Item types 20 and 21 refer to current periodicals.
    # NOTE however that an item is also considered a current periodical 
    # if the items current location is set to cur-per (80 or 250)
    item_type = V2::ItemType.find("displayName", copy['itemTypeID'])
    if item_type.blank?
      return false
    end

    type_id = item_type["policyNumber"].to_i
    if type_id == 20 || type_id == 21 
      return true 
    end

    # #  or return true if it is in a location that holds current periodicals
    curr_loc = V2::Location.find(copy['currentLocationID'])
    if curr_loc.blank?
      return false
    end

    loc_id = curr_loc['policyNumber'].to_i
    if loc_id == 80 || loc_id == 250 
      return true 
    end

    # at this point we couldn't find any reason to assume that this is a current periodical
    return false
  end

  def self.get_can_hold(item) 
    # If all the call numbers are the same for all the holdings
    # Ability(String name, String value, int message_code, String message)
    out = {}
    Rails.logger.debug("Can #{item.to_json} be held?")
    if same_call_numbers(item) 
      call_num = item['CallInfo'].first['callNumber']
      Rails.logger.debug "All holdings have same call number #{call_num}"
      if get_holdable_holding(item, call_num).nil?
        Rails.logger.debug "#{call_num} has no holdable holdings"
        return {name: "hold", value: "no", code: 3, message: "This item is not eligible for holds or recalls."}
      elsif locally_available?(item, call_num)
        return {name: "hold", value: "no", code: 1, message: "A copy of this item is currently available."}
      else
        return {name: "hold", value: "yes", code: 2, message: "Yes this catalog item can be held." }
      end
    else  
      Rails.logger.debug "Item has different call numbers"
      item['CallInfo'].each do |h|
        if is_holdable?(item['TitleAvailabilityInfo'], h) && !locally_available?(item, h["callNumber"] )
          return {name: "hold", value: "maybe", code: 4, message: "Some specific holdings can be held or recalled."}
        end
      end
      return {name: "hold", value: "no", code: 3, message: "This item is not eligible for holds or recalls."}
    end
  end

  # Get the first holding that matches the call num and is holdable
  def self.get_holdable_holding(item, call_num) 
    Rails.logger.debug "GetHoldableHolding for #{call_num}"
    item['CallInfo'].each do |h|
      next if h["callNumber"] != call_num 
      Rails.logger.debug "#{h.to_json} matches #{call_num}. Is it holdable?"
      if is_holdable?(item['TitleAvailabilityInfo'], h) 
        Rails.logger.debug "Yes; Holdable holding found"
        return h
      end
    end
    return nil
  end

  # Return true if a copy is  available
  def self.locally_available?(item, call_num)
    item['CallInfo'].each do |h|
      if h["callNumber"] != call_num 
        next 
      end

      # Must be non-remote library
      lib = V2::Library.find_by(code: h['libraryID'])
      if lib.nil? || !lib.nil? && lib.remote 
        next
      end

      # must have a circulating, available copy
      h['ItemInfo'].each do |copy|
        if is_copy_shadowed?(copy)
          next
        end
        if !copy['chargeable']
          next
        end

        curr_loc = V2::Location.find(copy['currentLocationID'])
        if curr_loc.blank? 
          next
        end
        item_type = V2::ItemType.find("displayName", copy['itemTypeID'])
        if item_type.blank?
          next
        end
        item_holdable =  V2::ItemType.holdable?( item_type['policyNumber'] )
        if curr_loc['onShelf'] || !item_holdable
          return true
        end
      end
    end
    return false
  end


  # return true if call numbers for all holding are the same
  def self.same_call_numbers(item) 
    if item['CallInfo'].count < 2 
      return true;
    end
    call_num = item['CallInfo'].first['callNumber']
    item['CallInfo'].each do |h|
      if h['callNumber'] != call_num
        return false;
      end
    end
    return true
  end
end
