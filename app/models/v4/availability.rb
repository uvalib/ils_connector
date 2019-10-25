class V4::Availability < SirsiBase
  include ActiveModel::Serializers::JSON
  base_uri env_credential(:sirsi_web_services_base)
  default_timeout 5

  attr_accessor :title_id, :data, :items

  def initialize id
    # remove leading u if present
    self.title_id = id.gsub(/^u/, '')
    self.data = find
    self.items = process_response
  end

  # used to name the root node in ActiveModel::Serializers
  def self.model_name
    'Availability'
  end

  REQUEST_PARAMS= { json: 'true', includeItemInfo: 'true',
                    includeCatalogingInfo: 'true',
                    includeAvailabilityInfo: 'true',
                    includeFields: '*', includeShadowed: 'BOTH'
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

        fields = []
        VISIBLE_FIELDS.each do |label, method|
          fields << field_data(label, send(method, holding, item) )
        end

        items << { call_number: holding['callNumber'],
          barcode: item['itemID'],
          on_shelf: on_shelf(holding, item),
          fields: fields
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
    if on_shelf(holding, item)
      "On Shelf"
    else
      "By Request"
    end
  end

  def on_shelf holding, item
    library = V4::Library.find holding['libraryID']
    current_location = V4::Location.find item['currentLocationID']
    # This might need to be ||
    library.on_shelf && current_location.on_shelf
  end

  # end field methods

end
