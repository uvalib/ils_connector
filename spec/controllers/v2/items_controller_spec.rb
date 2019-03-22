require 'rails_helper'

RSpec.describe V2::ItemsController, type: :controller do

  describe "GET #show" do
    it "returns http success" do
      get :show, params: {id: '333'}, format: :xml
      expect(response).to have_http_status(:success)
    end
  end

end
