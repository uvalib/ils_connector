class V4::RequestOption < SirsiBase
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON

  attr_accessor :user_id, :title_key, :user, :availability, :steps

  def initialize(option_params)
    self.user_id = option_params[:user_id]
    self.title_key = option_params[:title_key]
    self.user = V4::User.find(user_id)
    self.availability = V4::Availability.new(title_key)

    determine_options
    return
  end

  def determine_options
  end
  def hold_steps
  end
end