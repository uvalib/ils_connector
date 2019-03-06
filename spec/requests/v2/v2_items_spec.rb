require 'rails_helper'

RSpec.describe "V2::Items", type: :request do
  describe "GET /v2/items/:id" do
    let(:item_id) {'333'}
    before do
      get v2_item_path(id: item_id, format: :xml), headers: {'ACCEPT': 'application/xml'}
    end

    it 'works' do
      byebug
      expect(response).to have_http_status(200)
    end

    it 'matches the firehose response' do
      firehose_response = V1::Item.new(item_id).as_json

      v2_response = Hash.from_xml response.body

      diff = HashDiff.diff v2_response, firehose_response

      byebug

      expect(diff).to be_empty

    end
  end
end
