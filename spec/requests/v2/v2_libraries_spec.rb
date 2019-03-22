require 'rails_helper'

RSpec.describe "V2::Libraries", type: :request do
  describe "GET /v2/libraries" do
    before do
      get libraries_v2_lists_path(format: :xml),headers: {'ACCEPT': 'application/xml'}
    end

    it "works" do
      expect(response).to have_http_status(200)
    end

    it 'matches the firehose response' do
      firehose_response = V1::FirehoseLibrary.new.libraries.to_hash

      v2_response = Hash.from_xml response.body

      diff = HashDiff.diff firehose_response, v2_response

    end
  end
end
