class V4::Availability < SirsiBase
  include ActiveModel::Serializers::JSON
  base_uri env_credential(:sirsi_web_services_base)
  default_timeout 5

  attr_accessor :title_id, :data, :items, :request_options, :jwt_user

  def initialize id, jwt_user
    # remove leading u if present
    self.title_id = id.gsub(/^u/, '')
    self.jwt_user = jwt_user
    self.data = find
    if defined?( self.data ) && self.data.present?
      self.items = process_response if self.data.present?
      self.request_options = V4::Request::Options.new(self).list
    end
   end

  # used to name the root node in ActiveModel::Serializers
  def self.model_name
    'Availability'
  end

  REQUEST_PARAMS= { json: 'true',
                    includeItemInfo: 'true',
                    includeCatalogingInfo: 'true',
                    includeAvailabilityInfo: 'true',
                    includeCallNumberSummary: 'true',
                    includeFields: '*',
                    includeShadowed: 'NONE',
                    includeBoundTogether: 'true',
                    marcEntryID: '949,985,911,506,245'
  }

  def find
    self.class.ensure_login do
      data = {}
      response = self.class.get('/rest/standard/lookupTitleInfo',
                    query: REQUEST_PARAMS.merge(titleID: title_id),
                    headers: self.class.auth_headers,
                    max_retries: 0
                    )
      self.class.check_session(response)
      if response['TitleInfo'].present? && response['TitleInfo'].one? &&
          response['TitleInfo'].first['titleControlNumber'].present?
        data = response['TitleInfo'].first
      else
        # TODO: ATO ends up here and has no info
        # not found
      end
      data
    end
  end

  # This is a mapping of field labels to their method name
  VISIBLE_FIELDS = {"Library" => :library,
            'Current Location' => :current_location,
            'Call Number' => :call_number,
            'Barcode' => :barcode,
            #'Availability' => :availability
  }.freeze

  def process_response
    holding_data = data['CallInfo']

    items = []
    holding_data.map do |holding|
      holding['ItemInfo'].each do |item|
        begin
          next if hidden?(item)

          fields = []
          VISIBLE_FIELDS.each do |label, method|
            fields << field_data(label, send(method, holding, item) )
          end

          items << {
            barcode: item['itemID'],
            on_shelf: on_shelf?(holding, item),
            unavailable: unavailable?(item),
            notice: notice_text(item),
            fields: fields,
            library: library(holding, item),
            library_id: holding["libraryID"],
            current_location: current_location(holding, item),
            current_location_id: item['currentLocationID'],
            home_location_id: home_location_id(holding, item),
            call_number: call_number(holding, item),
            is_video: is_video(item),
            volume: volume(item)
          }
        rescue NoMethodError => error
          Rails.logger.error "Exception in Document #{title_id} - Item: #{item['itemID']} - #{error}\n#{error.backtrace.first}"
        end
      end
    end
    items
  end

  def field_data name, value, visible=true, type='text'
    { name: name,
      value: value,
      visible: visible,
      type: type
    }
  end

  def volume item
    vol_item = data['callSummary'].find do |call|
      call['itemID'] == item['itemID']
    end || {}
    return vol_item['analyticZ']
  end

  VIDEO_TYPES = %w(VIDEOJRNL VIDEO-DVD VIDEO-DISC VIDEO-CASS RSRV-VID4 RSRV-VID24)
  def is_video item
    VIDEO_TYPES.include? item['itemTypeID']
  end

  # Field methods below

  def library holding, item
    lib = V4::Library.find holding["libraryID"]
    lib.description if lib
  end

  def current_location holding, item
    loc = V4::Location.find item["currentLocationID"]
    loc.description if loc
  end

  def home_location_id holding, item
    item["homeLocationID"]
  end

  def call_number holding, item
    holding["callNumber"]
  end

  def barcode holding, item
    item["itemID"]
  end

  def availability holding, item
    if on_shelf?(holding, item)
      "On Shelf"
    elsif unavailable? item
      "Unavailable"
    else
      "By Request"
    end
  end

  def on_shelf? holding, item
    library = V4::Library.find holding['libraryID']
    current_location = V4::Location.find item['currentLocationID']
    # This might need to be ||
    library.on_shelf && current_location.on_shelf
  end

  def unavailable? item
    loc = V4::Location.find(item['currentLocationID'])
    loc.unavailable if loc
  end

  # Are not returned by this API
  def hidden? item
    loc = V4::Location.find(item['currentLocationID'])
    loc.shadowed || loc.online if loc
  end

  def notice_text item
    if V4::Location.medium_rare? item['currentLocationID']
      return V4::Location::MEDIUM_RARE_MESSAGE
    # No Course reserve note for now
    # elsif note = course_reserve_note(item)
    #   note
    elsif item['homeLocationID'] == 'SC-IVY'
      marc = data.dig("BibliographicInfo", 'MarcEntryInfo') || []
      notices = marc.select {|entry| entry['entryID'] == '506'} || []
      if notices
        return notices.map{|n| n['text'] }.join('</br>')
      end
    end
  end

  def course_reserve_note item
    if item['reserveCirculationRule'] == 'RESERVE'
      reserve_info = V4::CourseReserve.search_item item['itemID']

      if reserve_info.present?
        course = reserve_info['courseName']
        course_id = reserve_info['courseID']
        instructor = reserve_info['instructor']
        response = ["This item is on course reserves so is available for limited use through the circulation desk."]
        response << "Course Name: #{course}" if course
        response << "Course ID: #{reserve_info['courseID']}" if course_id
        response << "Instructor: #{reserve_info['instructor']}" if instructor
        return response.join "\n"
      end
    else
      nil
    end
  end

  # Begin fields for PDA service
  PDA_LOCATION_MAP = {
    'AL-PPDA'=>'ALD',
    'AS-PPDA'=>'ASTRO',
    'CH-PPDA'=>'CHEM',
    'CL-PPDA'=>'CLEM',
    'FA-PPDA'=>'FINE ARTS',
    'MA-PPDA'=>'MATH',
    'MU-PPDA'=>'MUSIC',
    'PH-PPDA'=>'PHYS',
    'SE-PPDA'=>'SCIENG'
  }

  def pda_hold_library
    marc = data.dig('BibliographicInfo', 'MarcEntryInfo')
    return nil if !marc
    marc_field = marc.find {|m| m['entryID'] == '949'}
    hold_id = marc_field['text']
    return PDA_LOCATION_MAP[hold_id]
  end

  def fund_code
    marc = data.dig('BibliographicInfo', 'MarcEntryInfo')
    return nil if !marc
    marc_field = marc.find {|m| m['entryID'] == '985'}
    return marc_field['text'].split(' ').first
  end

  def loan_type
    marc = data.dig('BibliographicInfo', 'MarcEntryInfo')
    return nil if !marc
    marc_field = marc.find {|m| m['entryID'] == '985'}
    return marc_field['text'].split(' ').last
  end

  # isbn specific to PDA service
  def pda_isbn
    marc = data.dig('BibliographicInfo', 'MarcEntryInfo')
    return nil if !marc
    marc_field = marc.find {|m| m['entryID'] == '911'}
    return marc_field['text']
  end

  # End PDA fields

  def title
    # title pulled from marc
    marc = data.dig('BibliographicInfo', 'MarcEntryInfo')
    return nil if !marc
    marc_field = marc.find {|m| m['entryID'] == '245'}
    return marc_field['text']
  end


  # end field methods

end
