require 'rails_helper'

RSpec.describe "V1::Libraries", type: :request do
  describe "GET /v1_libraries" do
    it "gets all libraries" do
      get v1_libraries_path
      expect(response).to be_success
      expect(json['libraries'].length).to eq 20
    end
  end
end
