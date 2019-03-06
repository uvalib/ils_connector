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
  xml.holding do
    @item['CallInfo'].each do |holding|
      xml.catalog_key
      xml.copy do
        holding['ItemInfo'].each do |copy|
          # noncurculating item == (chargable == false) && (homelocation == current_location)
          xml.circulate
          # lookup location with sirsi /policy/location GET
          xml.currentLocation do
            render 'locations/show', xml: xml, location: copy['CurrentLocationID']
          end
          xml.home_location do
            render 'locations/show', xml: xml, location: copy['HomeLocationID']
          end
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
      end # copy
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
    end
  end # holding
  xml.status
  xml.key
end
