require "rails_helper"

RSpec.describe V1::LibrariesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/v1/libraries").to route_to("v1/libraries#index")
    end

    it "routes to #show" do
      expect(:get => "/v1/libraries/1").to route_to("v1/libraries#show", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/v1/libraries").to route_to("v1/libraries#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/v1/libraries/1").to route_to("v1/libraries#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/v1/libraries/1").to route_to("v1/libraries#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/v1/libraries/1").to route_to("v1/libraries#destroy", :id => "1")
    end

  end
end
