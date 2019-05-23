require 'rails_helper'

RSpec.describe "V2::Lists", type: :request do
  describe "GET /v2/list/libraries" do
    before do
      get libraries_v2_lists_path(format: :xml),headers: {'ACCEPT': 'application/xml'}
    end

    it "works" do
      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/xml")
      expect(response).to be_ok
    end

    it 'matches the firehose response' do
      firehose_response = V1::FirehoseLibrary.new.libraries.to_hash

      v2_response = Hash.from_xml response.body
    end
  end

  describe "GET /v2/list/locations" do
    before do
      get locations_v2_lists_path(format: :xml),
        headers: {'ACCEPT': 'application/xml'}
    end

    it "works" do
      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/xml")
      expect(response).to be_ok
    end

    it 'matches the firehose response' do
      firehose_response = Nokogiri::XML(V1::Location.all)

      v2_response = Nokogiri::XML(response.body) do |config|
          config.noblanks
      end

      expect(v2_response.root.name).to eq('locations')
      v2_response.css('locations').children.each do |location|
        attributes = location.attributes.keys
        expect(attributes).to include('code', 'id')

        location_children = location.children.length
        # The only child is 'name'
        expect(location_children).to eq(1)

        name = location.css 'name'
        expect(name).to be_present
      end

    end

  end
end
