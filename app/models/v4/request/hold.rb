class V4::Request::Hold < V4::Request::Type

  PICKUP_LIBRARIES = %w(ALDERMAN CLEMONS DARDEN FINE-ARTS HEALTHSCI JAG LAW LEO MATH MUSIC PHYSICS SCI-ENG).freeze

  # Standard fields are defined in V4::RequestOption
  attr_accessor :pickup_library, :user_library

  validates_presence_of :user_library
  validates_inclusion_of :pickup_library, in: PICKUP_LIBRARIES, message: "%{value} is not a valid pickup library."

  def initialize options = {}
    super(options)

    return if self.errors.any?

    self.user_library = user[:homeLibrary]
    self.pickup_library = options[:pickup_library]

    create_hold
  end

  def label
    'Request this Item'
  end
  def description
    'Make a request to obtain this item from the library catalog.'
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
