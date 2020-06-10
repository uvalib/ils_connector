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
    if data.present?
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
                    includeShadowed: 'BOTH',
                    includeBoundTogether: 'true',
                    marcEntryID: '949,985,911'
  }

  def find
    self.class.ensure_login do
      data = {}
      response = self.class.get('/rest/standard/lookupTitleInfo',
                    query: REQUEST_PARAMS.merge(titleID: title_id),
                    headers: self.class.auth_headers
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
            'Availability' => :availability
  }.freeze

  def process_response
    holding_data = data['CallInfo']

    items = []
    holding_data.map do |holding|
      holding['ItemInfo'].each do |item|
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
          current_location: current_location(holding, item),
          call_number: call_number(holding, item),
          volume: volume(item)
        }
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

  # Field methods below

  def library holding, item
    lib = V4::Library.find holding["libraryID"]
    lib.description if lib
  end

  def current_location holding, item
    loc = V4::Location.find item["currentLocationID"]
    loc.description if loc
  end

  def call_number holding, item
    holding["callNumber"]
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
    note = if V4::Location.medium_rare? item['currentLocationID']
             V4::Location::MEDIUM_RARE_MESSAGE
           elsif note = course_reserve_note(item)
             note
           end
    note
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

  def pda_hold_library
    marc = data.dig('BibliographicInfo', 'MarcEntryInfo')
    return nil if !marc
    marc_field = marc.find {|m| m['entryID'] == '949'}
    return marc_field['text']
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


  # end field methods

end
