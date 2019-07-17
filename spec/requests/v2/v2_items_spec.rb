require 'rails_helper'

RSpec.describe "V2::Items", type: :request do
  describe "GET /v2/items/:id" do
    let(:item_id) {'333'}
    before do
      get v2_item_path(id: item_id, format: :xml), headers: {'ACCEPT': 'application/xml'}
    end

    it 'works' do
      expect(response).to have_http_status(200)
    end

    it 'matches the firehose response' do
      firehose_response = V1::Item.new(item_id).as_json

      v2_response = Hash.from_xml response.body

      expect(v2_response['catalogItem']).to be_present

      item = v2_response['catalogItem']
      expect(item.keys).to match_array(%w(key canHold holding status))

      holding = item['holding']
      holding_keys = ["callNumber", "callSequence", "holdable", "shadowed", "catalogKey", "copy", "library", "shelvingKey"]
      expect(holding.keys).to match_array(holding_keys)

      copy = holding['copy']
      copy_keys = ["copyNumber", "currentPeriodical", "barCode", "shadowed", "circulate", "currentLocation", "homeLocation", "itemType", "lastCheckout"]
      expect(copy.keys).to match_array(copy_keys)




    end
  end
end
