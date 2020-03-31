class V4::Request::Type < SirsiBase
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON

  base_uri env_credential(:sirsi_web_services_base)
  default_timeout 5

  attr_accessor :user_id, :title_key, :user, :user_key, :availability, :steps
  validates_presence_of :title_key, :user_id, :user, :label, :description, :steps

  def initialize(options)

    if options[:user_id]
      self.user_id = options[:user_id]
      self.user = V4::User.find(user_id)
      if user.empty?
        # Sirsi user not found
        self.errors[:user_key] << "does not have a Sirsi account"
        return
      end
      self.user_key = user[:key]
    else
      self.errors[:user_id] << "is required"
      return
    end

    if options[:title_key]
      # remove leading u
      self.title_key = options[:title_key].delete_prefix 'u'
      self.availability = V4::Availability.new(title_key)
    else
      self.errors[:title_key] << "is required"
      return
    end

    return
  end

  def self.determine_options title_key
    #V4::Request::Type::Hold

    []

  end

end