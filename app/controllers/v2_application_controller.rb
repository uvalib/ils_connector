class V2ApplicationController < ApplicationController
  include ActionView::Layouts
  include ActionController::ImplicitRender
  include XmlHelpers


  before_action :swap_version

  V1CONTROLLERS = %w(items users requests)

  def swap_version
    if !Rails.env.test? && V1CONTROLLERS.include?(controller_name)
      redirect_to(controller: "v1/#{controller_name}", action: action_name) and return
    end
  end

end
