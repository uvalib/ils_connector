class V2ApplicationController < ApplicationController
  include ActionView::Layouts
  include ActionController::ImplicitRender
  include XmlHelpers

  respond_to :xml

  before_action :swap_version

  V1CONTROLLERS = %w(items users requests lists)

  def swap_version
    if V1CONTROLLERS.include? controller_name
      redirect_to(controller: "v1/#{controller_name}", action: action_name) and return
    end
  end

end
