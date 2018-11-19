require 'rails_helper'

RSpec.describe V3::IvyRequestsController, type: :request do
  before do
    @user = create :api_user
    sign_in @user
    @headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
    @headers = Devise::JWT::TestHelpers.auth_headers(@headers, @user)
    @ivy_request = build :ivy_request


  end

  describe 'POST /v2/ivy_requests' do
    before do
      post v3_ivy_requests_path,
        params: {ivy_request: @ivy_request.attributes}.to_json,
        headers: @headers
    end

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'creates an IvyRequest' do
      expect(V2::IvyRequest.count).to equal 1
    end
  end
end
