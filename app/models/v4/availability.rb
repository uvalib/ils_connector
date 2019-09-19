class V4::Availability < SirsiBase
  base_uri env_credential(:sirsi_web_services_base)
  default_timeout 5

  # PLACEHOLDER BELOW - Copied from V2::Item

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
end
