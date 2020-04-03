class V4::Request::Hold < V4::Request::Type

  PICKUP_LIBRARIES = %w(ALDERMAN CLEMONS DARDEN FINE-ARTS HEALTHSCI JAG LAW LEO MATH MUSIC PHYSICS SCI-ENG).freeze

  # Standard fields are defined in V4::RequestOption
  attr_accessor :pickup_library, :home_library, :item_barcode

  validates_inclusion_of :pickup_library, in: PICKUP_LIBRARIES, message: "%{value} is not a valid pickup library."
  validates_presence_of :home_library
  validates_presence_of :item_barcode, message: "is required. Use the first item for title level requests"

  def initialize options = {}
    super(options)

    return if self.errors.any?

    self.home_library = user[:homeLibrary]
    self.pickup_library = options[:pickup_library]
    self.item_barcode = options[:item_barcode]

    if self.valid?
      send_hold
    end
  end

  def label
    'Request this Item'
  end
  def description
    'Make a request to obtain this item from the library catalog.'
  end


  private
  def send_hold

    self.class.ensure_login do

      # Get Item info
      # For itemBarcode if user had to choose an anlyticZ value,
      # use the first itemID from the callSummary for the analyticZ the user chose.
      # Otherwise, use the first itemID from the CallInfo (in the lookupTitleInfo response).

      # Users set to LEO library are LEO-able
      # TODO incorporate LEO+
      working_library = home_library == 'LEO' ? 'LEO' : 'UVA-LIB'
      headers = {'sd-working-libraryid' => working_library}
      hold_data = {
        holdType: 'TITLE',
        holdRange: 'GROUP',
        recallStatus: 'STANDARD',
        pickupLibrary: {resource: '/policy/library',
                        key: pickup_library
        },
        itemBarcode: item_barcode,
        patronBarcode: user['barcode']
      }
      Rails.logger.info headers
      Rails.logger.info hold_data
      response = self.class.post('/circulation/holdRecord/placeHold?includeFields=holdRecord{*}',
                                 body: hold_data.to_json,
                                 headers: self.class.auth_headers.merge(headers)
                     )
      self.class.check_session(response)
      if response['messageList'].present?
        response['messageList'].each do |error|
          if error['code'] == 'keyParseError'
            self.errors[:title_key] << 'Invalid title_key.'
          else
            self.errors[:sirsi] << error['message']
          end
        end
      end
      Rails.logger.info response

    end
  end
end
