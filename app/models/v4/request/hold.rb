class V4::Request::Hold < V4::Request::RequestBase

  PICKUP_LIBRARIES = %w(ALDERMAN CLEMONS DARDEN FINE-ARTS HEALTHSCI JAG LAW LEO MATH MUSIC PHYSICS SCI-ENG).freeze

  # Standard fields are defined in V4::RequestOption
  attr_accessor :pickup_library, :working_library, :item_barcode, :is_scan, :comment

  validates_inclusion_of :pickup_library, in: PICKUP_LIBRARIES, message: "%{value} is not a valid pickup library."
  validates_presence_of :working_library
  validates_presence_of :item_barcode, message: "is required."

  def initialize options = {}
    super(options)

    return if self.errors.any?

    self.pickup_library = options[:pickup_library]
    self.item_barcode = options[:item_barcode]

    if options[:type] == :scan
      self.is_scan = true
      self.working_library = 'LEO'
      self.comment = options[:illiad_tn]
    else

      # Users set to LEO library are LEO-able
      # TODO incorporate LEO+
      #working_library = 'UVA-LIB'
      self.working_library = user[:homeLibrary] == 'LEO' ? 'LEO' : 'UVA-LIB'
    end

    if self.valid?
      send_hold
    end
  end

  # deletes hold from Sirsi
  def self.delete_hold id
    ensure_login do
      response = delete("/circulation/holdRecord/key/#{id}",
                                 headers: auth_headers.merge(headers)
                     )
      check_session(response)
      return response.code == 204
    end
  end

  private
  def send_hold

    self.class.ensure_login do

      # Get Item info
      # For itemBarcode if user had to choose an anlyticZ value,
      # use the first itemID from the callSummary for the analyticZ the user chose.
      # Otherwise, use the first itemID from the CallInfo (in the lookupTitleInfo response).

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

      if is_scan
        # LEO Scan Patron
        hold_data[:patronBarcode] = '999999462'
        hold_data[:comment] = comment
      end

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

  # Fill a hold by
  # - Retrieve item info with barcode
  # - TODO: Lookup Illiad user for address
  # - Untransit Item
  # - Checkout item to user
  # Return data to print:
  # Item Title, Item Author, ItemID, User’s Name, AltID, and Delivery Location
  def self.fill_hold barcode, override_code
    self.ensure_login do

      output = {error_messages: []}

      # working Library based on staff station location
      # Item location is probably good for now
      working_library = 'LEO'
      headers = {'SD-Working-LibraryID' => working_library}

      # Get Item
      params = {includeFields: 'holdRecordList{placedLibrary,pickupLibrary,patron{alternateID,displayName,barcode}},bib{title,author,currentLocation},transit{destinationLibrary,holdRecord{placedLibrary,pickupLibrary,patron{alternateID,displayName,barcode}}}'}
      item_response = self.get("/catalog/item/barcode/#{barcode}",
        query: params,
        headers: self.auth_headers.merge(headers)
        )
      self.check_session(item_response)

      if item_response['messageList'].present?
        output[:error_messages].push *item_response['messageList']
      end

      output[:title] = item_response.parsed_response.dig('fields', 'bib', 'fields', 'title')
      output[:author] = item_response.parsed_response.dig('fields', 'bib', 'fields', 'author')
      output[:item_id] = barcode
      has_transit = item_response.dig('fields', 'transit', 'key').present?
      transit_destination = item_response.dig('fields', 'transit', 'fields', 'destinationLibrary', 'key')

      transit_hold = item_response.dig('fields','transit','fields','holdRecord')
      item_hold = item_response.parsed_response.dig('fields', 'holdRecordList').first
      hold = transit_hold || item_hold
      Rails.logger.info("TransitHold: #{transit_hold} | FirstItemHold: #{item_hold}")

      if !hold
        output[:error_messages].push "No hold for this item."
        return output
      end

      output[:user_full_name] = hold.dig('fields', 'patron', 'fields', 'displayName')
      output[:user_id] = hold.dig('fields', 'patron', 'fields', 'alternateID')
      patron_barcode = hold.dig('fields', 'patron', 'fields', 'barcode')
      output[:pickup_library] = hold.dig('fields', 'pickupLibrary', 'key')
      library = output[:pickup_library]

      # Untransit if necessary
      if has_transit
        untransit_response = untransit_loop(barcode, override_code, library)
        if untransit_response['currentStatus'] != 'ON_SHELF'
          output[:error_messages].push *untransit_response['messageList'] || {message: untransit_response['currentStatus']}
          Rails.logger.error("Untransit Error: #{untransit_response.parsed_response}")
          return output
        end
      end

      # Checkout to user
      checkout_response = checkout_loop(patron_barcode, barcode, library, override_code)

      if !checkout_response.success?
        output[:error_messages].push *checkout_response['messageList']
      end

      return output
    end
  end

  # retry sirsi call using the override code until it succeeds or the blocker cannot be overridden
  def self.untransit_loop barcode, override_code, working_library
    blocking_prompts = []
    response = nil
    # loop until the override code doesnt work anymore
    while blocking_prompts.uniq.length == blocking_prompts.length do

      override_header = 'CKOBLOCKS'
      if blocking_prompts.any? && override_code.present?
        override_header += ';' + blocking_prompts.join("/#{override_code};")
      end

      headers = {'SD-Working-LibraryID' => working_library,
        'SD-Prompt-Return' => override_header
      }
      # untransit needs to happen at the delivery location
      response = self.post("/circulation/transit/untransit",
        body: {itemBarcode: barcode}.to_json,
        headers: self.auth_headers.merge(headers)
      )
      self.check_session(response)

      # Blocking prompt found
      if response['promptRequired']
        blocking_prompts << response.dig('dataMap', 'promptType')
      else
        break
      end
    end
    return response
  end


  def self.checkout_loop(patron_barcode, item_barcode, working_library, override_code)
    blocking_prompts = []
    response = nil

    # loop until the override code doesnt work anymore
    while blocking_prompts.uniq.length == blocking_prompts.length do
      override_header = 'CKOBLOCKS'
      if blocking_prompts.any? && override_code.present?
        override_header += ';' + blocking_prompts.join("/#{override_code};") + "/#{override_code};"
      end
      headers = {'SD-Working-LibraryID' => working_library,
        'SD-Prompt-Return' => override_header
      }

      response = self.post("/circulation/circRecord/checkOut",
        body: { patronBarcode: patron_barcode,
          itemBarcode: item_barcode
        }.to_json,
        headers: self.auth_headers.merge(headers)
      )
      self.check_session(response)

      # Blocking prompt found
      if response['promptRequired'] && override_code.present?
        blocking_prompts << response.dig('dataMap', 'promptType')
      else
        break
      end
    end
    return response
  end
end
