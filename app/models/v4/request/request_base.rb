class V4::Request::RequestBase < SirsiBase
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON

  base_uri env_credential(:sirsi_web_services_base)
  default_timeout 5

  attr_accessor :user_id, :title_key, :user, :availability
  validates_presence_of :user_id, :user, :label, :description

  def initialize(options)

    # Check for major issues here, such as missing user_id or item
    if options[:user_id]
      self.user_id = options[:user_id]
      self.user = V4::User.find(user_id)
      unless user.present?
        # Sirsi user not found
        self.errors[:user_id] << "does not have a Sirsi account"
        return
      end
    else
      self.errors[:user_id] << "is required. Log in first"
      return
    end

    if options[:title_key]
      # remove leading u
      self.title_key = options[:title_key].delete_prefix 'u'
      #self.availability = V4::Availability.new(title_key)
    end

  end



end