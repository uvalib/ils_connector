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
            xml.item_type do
              #render 'item_type/show', xml: xml, location: copy['itemTypeID']
              xml.id
              xml.code
            end
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
