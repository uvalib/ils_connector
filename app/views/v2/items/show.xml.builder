xml.instruct!
# lookup with /rest/standard/lookupTitleInfo?titleID=145&json=true&includeItemInfo=true&includeFields=*
#
xml.item do
  ## chargable == holdable ex- 100
  xml.canHold do
    xml.message
    xml.message_code
    xml.name
    xml.value
  end
  @item['CallInfo'].each do |holding|
    xml.holding do
      xml.catalog_key
        holding['ItemInfo'].each do |copy|
          xml.copy do
            # noncurculating item == (chargable == false) && (homelocation == current_location)
            xml.circulate 
            render(partial: 'v2/locations/show', locals: {builder: xml, type: "currentLocation", loc: V2::Location.find(copy['currentLocationID']) })
            render(partial: 'v2/locations/show', locals: {builder: xml, type: "homeLocation", loc: V2::Location.find(copy['homeLocationID']) })
            render(partial: 'v2/item_types/show', locals: {builder: xml, item_type: V2::ItemType.find("displayName", copy['itemTypeID']) })
            xml.lastCheckout
            xml.copy_number 
            xml.currentPeriodical
            xml.barCode copy['itemID']
            xml.shadowed
          end 
        end  # copy
      xml.library do
        xml.deliverable
        xml.holdable
        xml.name
        xml.remote
        xml.code
        xml.id
      end
      xml.shelvingKey
      xml.callNumber
      xml.callSequence
      xml.holdable
      xml.shadowed
    end # holding
  end 
  xml.status
end


# {"titleID"=>333, "titleControlNumber"=>nil, "catalogFormatID"=>nil, "catalogFormatType"=>nil, "materialType"=>nil, 
#   "baseCallNumber"=>nil, "author"=>nil, "title"=>nil, "sisacID"=>nil, "publisherName"=>nil, 
#   "datePublished"=>nil, "yearOfPublication"=>nil, "extent"=>nil, "netLibraryID"=>nil, 
#   "numberOfCallNumbers"=>nil, "numberOfTitleHolds"=>nil, "copiesOnOrder"=>nil, "outstandingCopiesOnOrder"=>nil, 
#   "numberOfBoundwithLinks"=>nil, "callSummary"=>[], "TitleAvailabilityInfo"=>nil, "ISBN"=>[], "SICI"=>[], "UPC"=>[], 
#   "OCLCControlNumber"=>nil, "TitleOrderInfo"=>[],
#    "CallInfo"=>[{"libraryID"=>"MUSIC", "classificationID"=>"LC", "callNumber"=>"M2 .C8 no.43", "numberOfCopies"=>1, "boundParentAuthor"=>nil, 
#       "boundParentTitle"=>nil, "ItemInfo"=>[{"itemID"=>"X002055251", "itemTypeID"=>"MUSI-SCORE", "currentLocationID"=>"STACKS", 
#         "homeLocationID"=>"STACKS", "dueDate"=>nil, "recallDueDate"=>nil, "reshelvingLocationID"=>nil, "transitSourceLibraryID"=>nil, 
#         "transitDestinationLibraryID"=>nil, "transitReason"=>nil, "transitDate"=>nil, "chargeable"=>false, "numberOfHolds"=>nil, "reserveCollectionID"=>nil, "reserveCirculationRule"=>nil, "mediaDeskID"=>nil, "fixedTimeBooking"=>false, "publicNote"=>nil, "staffNote"=>"{ * mus}", "itemCategories"=>[]}]}], "BibliographicInfo"=>nil, "MarcHoldingsInfo"=>[], "BoundwithLinkInfo"=>[]}