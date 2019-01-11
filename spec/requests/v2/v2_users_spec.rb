require 'rails_helper'

RSpec.describe "V2::Users", type: :request do
  describe "GET /v2/users/:id" do
    before do
      user_id = 'naw4t'

      get v2_user_path(id: user_id, format: :xml), headers: {'ACCEPT': 'application/xml'}
    end

    it "works" do
      expect(response).to have_http_status(200)
    end

    it 'matches the firehose response' do
      firehose_response = V1::User.new.libraries.to_hash

      v2_response = Hash.from_xml response.body

      diff = HashDiff.diff firehose_response, v2_response

    end
  end
end
