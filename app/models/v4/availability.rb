class V4::Availability < SirsiBase
  include ActiveModel::Serializers::JSON
  base_uri env_credential(:sirsi_web_services_base)
  default_timeout 5

  attr_accessor :title_id, :data, :holdings


  def initialize id
    self.title_id = id
    self.data = find
    holdings = process_response

  end
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

  COLUMNS = {library: 'Library',
#             currentLocation: 'Current Location',
             callNumber: 'Call Number',
             available: "Availability"
  }.freeze
  def process_response
    holding_data = data['CallInfo']

    self.holdings = holding_data.map do |holding|
      fields = []
      fields << field_data('Library', holding['libraryID'])
      fields << field_data('Call Number', holding['callNumber'])
      fields << field_data('Availability', 'n/a')
      { id: holding['callNumber'],
        fields: fields
      }
    end
  end
  def field_data name, value, visible=true, type='text'
    {name: name,
     value: value,
     visible: visible,
     type: type
    }
  end

end
