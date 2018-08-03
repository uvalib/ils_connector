require 'rails_helper'

RSpec.describe ApiUsersController, type: :controller do
  describe 'Sign in' do
    it 'authorizes api users' do
      u = create(:api_user)
      headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

    end
  end

end
