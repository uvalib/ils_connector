class V2ApplicationController < ApplicationController
  include ActionView::Layouts
  include ActionController::ImplicitRender
  include XmlHelpers

  before_action :items_only

  def items_only
    if controller_name != 'items'
      raise ActionController::RoutingError.new('Not Found')
    end
  end


end
