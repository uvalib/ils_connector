xml.instruct!
# lookup with rest/standard/lookupTitleInfo?titleID=752166&includeItemInfo=true&callList=true
#                                           &includeCatalogingInfo=true&includeOPACInfo=true&includeAvailabilityInfo=true
#                                           &includeFields=*&includeOrderInfo=true&includeMarcHoldings=true&includeShadowed=BOTH
#
xml.catalogItem key: @item['titleID'] do
  ## chargable == holdable ex- 100
  xml.canHold do
    xml.message
    xml.message_code
    xml.name
    xml.value
  end

  @item['CallInfo'].each_with_index do |holding, idx|
    xml.holding callNumber: holding['callNumber'], callSequence: idx+1, holdable: V2::Item.isHoldable?(@item, idx) do
      xml.catalogKey @item['titleID']

      holding['ItemInfo'].each do |copy|
        xml.copy copyNumber: 0, currentPeriodical: "false", barcode: copy['itemID'], shadowed: "false" do
          # noncurculating item == (chargable == false) && (homelocation == current_location)
          xml.circulate 
          render(partial: 'v2/locations/show', locals: {builder: xml, type: "currentLocation", loc: V2::Location.find(copy['currentLocationID']) })
          render(partial: 'v2/locations/show', locals: {builder: xml, type: "homeLocation", loc: V2::Location.find(copy['homeLocationID']) })
          render(partial: 'v2/item_types/show', locals: {builder: xml, item_type: V2::ItemType.find("displayName", copy['itemTypeID']) })
          xml.lastCheckout
        end  # copy 
      end  # holding

      render(partial: 'v2/lists/library', locals: {builder: xml, lib: V2::Library.find_by(code: holding['libraryID']) })

      xml.shelvingKey
      xml.callNumber
      xml.callSequence
      xml.holdable
      xml.shadowed
    end # catalok_key
  end 
  xml.status
end