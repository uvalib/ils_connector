xml.instruct! :xml, encoding: 'UTF-8', standalone: 'yes'

xml.catalogItem key: @item['titleID'] do
  render(partial: '/v2/items/can_hold', locals: {builder: xml, hold: V2::Item.get_can_hold(@item) })

  @item['CallInfo'].each_with_index do |holding, idx|
    xml.holding callNumber: holding['callNumber'], callSequence: idx+1, 
                holdable: V2::Item.is_holdable?(holding), shadowed:  V2::Item.is_holding_shadowed?(holding) do
      xml.catalogKey @item['titleID']

      holding['ItemInfo'].each_with_index do |copy, cpy_idx|
        xml.copy copyNumber: cpy_idx+1, currentPeriodical: V2::Item.is_current_periodical?(copy), barcode: copy['itemID'], 
                 shadowed:  V2::Item.is_copy_shadowed?(copy) do
          xml.circulate V2::Item.circulate?(copy)
          render(partial: '/v2/locations/show', locals: {builder: xml, type: "currentLocation", loc: V2::Location.find(copy['currentLocationID']) })
          render(partial: '/v2/locations/show', locals: {builder: xml, type: "homeLocation", loc: V2::Location.find(copy['homeLocationID']) })
          render(partial: '/v2/item_types/show', locals: {builder: xml, item_type: V2::ItemType.find("displayName", copy['itemTypeID']) })
          xml.lastCheckout "2019-06-26T04:27:16-04:00"
        end 
      end

      render(partial: '/v2/lists/library', locals: {builder: xml, lib: V2::Library.find_by(code: holding['libraryID']) })
      
      k = holding["shelvingKey"]
      if k.blank?
        k = holding["callNumber"]
      end
      xml.shelvingKey k
    end 
  end 
  xml.status  0 # UNKNOWN - not in API response, in Firehose, catalogItem.set/getStatus is never called. Seems like always 0
end
