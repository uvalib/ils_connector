class V2ApplicationController < ApplicationController
  include ActionView::Layouts
  include ActionController::ImplicitRender

  respond_to :xml

end
