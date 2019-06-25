class V2::Item < SirsiBase
  base_uri env_credential(:sirsi_web_services_base)

  ##rest/standard/lookupTitleInfo?titleID=752166&includeItemInfo=true&callList=true&includeCatalogingInfo=true
  #     &includeOPACInfo=true&includeAvailabilityInfo=true&includeFields=*&includeOrderInfo=true
  #     &includeMarcHoldings=true&includeShadowed=BOTH
  REQUEST_PARAMS= { json: 'true', includeItemInfo: 'true', callList: 'true', includeCatalogingInfo: 'true',
    includeOPACInfo: 'true', includeAvailabilityInfo: 'true', includeFields: '*', includeOrderInfo: 'true',
    includeMarcHoldings: 'true', includeShadowed: 'BOTH'
  }

  def self.find item_id
    ensure_login do
      data = {}.with_indifferent_access
      response = get('/rest/standard/lookupTitleInfo',
        query: REQUEST_PARAMS.merge(titleID: item_id),
        headers: auth_headers
      )
      if response['TitleInfo'].present? && response['TitleInfo'].one?
        data = response['TitleInfo'].first
      else
        # not found or more than one (should never happen?)
      end
      data
    end
  end

  # If all copies are shadowed, the holding is shadowed
  def self.is_holding_shadowed?(holding)
    # puts "==> IS HOLDING SHADOWED #{holding}"
    holding['ItemInfo'].each do |cpy|
      if is_copy_shadowed?(cpy) == false
        # puts "COPY IS NOT SHADOWED, SO HOLDING IS NOT SHADOWED"
        return false
      end
    end
    return true
  end

  # A copy is shadowed if it has no location, or its location is shadowed
  def self.is_copy_shadowed?(copy)
    # puts "=====>IS COPY SHADOWED #{copy}"
    if copy['currentLocationID'].blank? || copy['homeLocationID'].blank? 
      return true
    end
    curr_loc = V2::Location.find(copy['currentLocationID'])
    home_loc = V2::Location.find(copy['homeLocationID'])
    if copy['homeLocationID'] == "RSRVSHADOW"
      # puts "SHADOWED! RSRVSHADOW"
      return curr_loc['shadowed']
    end
    return curr_loc["shadowed"] || home_loc["shadowed"]
  end

  def self.circulate?(copy)
    if copy['chargeable']
      return "Y"
    end
    return "N"
  end

	#  Returns true only if there is an item can can be held, and if no copies are available.
  def self.is_holdable?(holding)
    if is_holding_shadowed?(holding)
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
 		  if curr_loc['holdable'] && cpy['chargeable'] && item_holdable
         has_holdable_item = true
      end
      if curr_loc['onShelf'] || !item_holdable
        has_available_item = true
      end
    end
    return has_holdable_item == true && has_available_item == false
  end

  def self.get_can_hold(item) 
    # If all the call numbers are the same for all the holdings
    # Ability(String name, String value, int message_code, String message)
    out = {}
    if same_call_numbers(item) 
      call_num = item['CallInfo'].first['callNumber']
      puts "HOLDABLE INFO; SAME CN #{call_num}"
		# 	if (getHoldableHolding(call_num) == null) {
		# 		return new Ability(Ability.CAN_HOLD, Ability.NO_VALUE, 3, "This item is not eligible for holds or recalls.");
		# 	} else if (callNumberLocallyAvailableAndCirculating(call_num)) {
		# 		log.info("This catalog item is locally avaiable:");
		# 		return new Ability(Ability.CAN_HOLD, Ability.NO_VALUE, 1, "A copy of this item is currently available.");
		# 	} else {
		# 		log.info("No copies are available, but one is holdable.");
		# 		return new Ability(Ability.CAN_HOLD, Ability.YES_VALUE, 2, "Yes this catalog item can be held.");
    # 	}
    return {"code": "3", "name": "hold", "value": "no", "message": "This item is not eligible for holds or recalls!"}
		else  
      item['CallInfo'].each do |h|
		# 		if (h.is_holdable() && !callNumberLocallyAvailableAndCirculating(h.getCallNumber()) ) {
		# 			return new Ability(Ability.CAN_HOLD, Ability.MAYBE_VALUE, 4, "Some specific holdings can be held or recalled.");
		# 		}
      end
      return {code: "3", name: "hold", value: "no", message: "This item is not eligible for holds or recalls."}
    end
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
