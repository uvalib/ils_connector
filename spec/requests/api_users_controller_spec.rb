require 'rails_helper'

RSpec.describe ApiUsers::SessionsController, type: :request do
  describe 'GET /api_users/sign_in' do
    before do
      headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
      user = create(:api_user)
      post('/api_users/sign_in', params: {api_user: {email: user.email, password: user.password}}.to_json,
           headers: headers )
      body = JSON.parse response.body

    end
    it 'authorizes api users and returns a JWT id' do
      expect(response).to be_successful
      expect(body['jti']).to be_present
    end
  end

end
