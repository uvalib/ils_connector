class V2::Item < SirsiBase

  base_uri env_credential(:sirsi_web_services_base)

  REQUEST_PARAMS= { json: 'true',
                    includeItemInfo: 'true',
                    callList: 'true'
  }

  attr_reader :data

  def initialize item_id
    super()
    @data ||= find item_id
  end

  def self.find item_id
    ensure_login do
      data = {}.with_indifferent_access
      response = get('/rest/standard/lookupTitleInfo',
                                query: REQUEST_PARAMS.merge(titleID: item_id),
                                headers: auth_headers
                               )
      if response['TitleInfo'].present? && response['TitleInfo'].one?
        data = response['TitleInfo'].first
      else
        # not found or more than one (should never happen?)
      end
      data
    end
  end
end
