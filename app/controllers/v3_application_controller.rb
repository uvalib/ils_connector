class V3ApplicationController < ApplicationController
  before_action :authenticate_api_user!, except: :landing

end
