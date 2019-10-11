class V4ApplicationController < ApplicationController
#  before_action :authenticate_api_user!, except: :landing
  before_action do
    self.namespace_for_serializer = V4
  end
end
