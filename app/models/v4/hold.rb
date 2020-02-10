class V4::Hold < SirsiBase
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  base_uri env_credential(:sirsi_web_services_base)
  default_timeout 5

  PICKUP_LIBRARIES = %w(ALDERMAN CLEMONS DARDEN FINE-ARTS HEALTHSCI JAG LAW LEO MATH MUSIC PHYSICS SCI-ENG).freeze

  attr_accessor :title_key, :pickup_library, :user_id, :user_key, :user_library, :response

  validates_presence_of :title_key, :pickup_library,
    :user_id
  validates_inclusion_of :pickup_library, in: PICKUP_LIBRARIES, message: "%{value} is not a valid pickup library."


  def initialize options = {}

    # remove leading u
    self.title_key = options[:title_key].delete_prefix 'u'

    self.pickup_library = options[:pickup_library]
    self.user_id = options[:user_id]

    user = V4::User.find_library(user_id)
    self.user_key = user[:key]
    self.user_library = user[:library]

    if user.empty?
      self.errors[:user_id] << "User not found."
      return
    end

    if self.valid?
      create_hold
    else
      # respond with errors
      return
    end

  end


  private
  def create_hold

    self.class.ensure_login do
      # Users set to LEO library are LEO-able
      headers = {'SD-Working-LibraryID': user_library}

      hold_data = {
        holdType: 'TITLE',
        holdRange: 'GROUP',
        recallStatus: 'STANDARD',
        pickupLibrary: {resource: '/policy/library',
                        key: pickup_library
        },
        bib: {resource: '/catalog/bib', key: title_key},
        patron: {resource: '/user/patron', key: user_key}
      }
      response = self.class.post('/circulation/holdRecord/placeHold',
                                 body: hold_data.to_json,
                                 headers: self.class.auth_headers.merge(headers)
                     )
      self.class.check_session(response)
      if response['messageList'].any?
        response['messageList'].each do |error|
          if error['code'] == 'keyParseError'
            self.errors[:title_key] << "Invalid title_key."
          else
            self.errors[:sirsi] << error['message']
          end
        end
        # errors found
        return
      end
    end


  end
end
