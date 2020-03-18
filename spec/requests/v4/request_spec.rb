require 'rails_helper'

RSpec.describe "V4::Request", type: :request do
  describe "GET /v4/request/options/:id" do
    let(:title_key) {'4684522'}
    let(:user_id) {'naw4t'}

    before do
      get options_v4_requests_path(params: {title_key: title_key, user_id: user_id}, format: :json), headers: {'ACCEPT': 'application/json'}
    end

    it 'works' do
      expect(response).to have_http_status(200)
    end
  end
end