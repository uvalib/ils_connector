require 'rails_helper'

RSpec.describe "V2::Users", type: :request do
  describe "GET /v2/users/:id" do
    let(:user_id) { 'mhw8m' }
    before do

      get v2_user_path(id: user_id, format: :xml), headers: {'ACCEPT': 'application/xml'}
    end

    it "works" do
      expect(response).to have_http_status(200)
    end

    it 'matches the firehose response' do
      pending 'Need to finish'
      firehose_response = V1::User.new(user_id).as_json['user']

      v2_response = Hash.from_xml response.body

      diff = HashDiff.diff v2_response, firehose_response


      expect(diff).to be_empty

    end
  end
end
