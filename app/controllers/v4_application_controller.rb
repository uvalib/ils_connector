class V4ApplicationController < ApplicationController
  before_action do
    self.namespace_for_serializer = V4
  end
end
