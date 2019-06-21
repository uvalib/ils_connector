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

  # RSRVSHADOW
  def self.isShadowed?(item, holdingIdx)
  end

  def self.isHoldable?(item, holdingIdx)
    # TODO logic here
    # https://github.com/uvalib/firehose/blob/438fc5bd4d7e1113ea56fb0bf5362bdf408fda11/src/main/java/edu/virginia/lib/firehose2/models/CatalogItem.java#L162
    # NOTE: holds are for if something is checked out and you want it next, so if copies are available, can't hold
    puts "COPIES AVAILABLE: #{item['TitleAvailabilityInfo']['totalCopiesAvailable']}"
    return item['TitleAvailabilityInfo']['totalCopiesAvailable'] == 0
  end
end
