require 'rails_helper'

RSpec.describe "V1::Libraries", type: :request do
  describe "GET /lists/libraries" do
    it "gets all libraries" do
      get libraries_v1_lists_path
      expect(response).to be_successful
      v1_response = Hash.from_xml response.body
      expect(v1_response.dig('libraries', 'library').count).to eq 21
    end
  end
end
