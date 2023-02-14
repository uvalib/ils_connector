class V4::Metadata < SirsiBase

  base_uri env_credential(:sirsi_web_services_base)
  TRACKSYS_HEADERS = { "SD-Originating-App-Id": "TrackSys", "x-sirs-clientID": "TRACKSYS"}

  REQUEST_PARAMS= { json: 'true',
    includeFields: 'bib',
    includeShadowed: 'NONE'
  }

  attr_accessor :bib, :key
  def initialize fields
    @bib = fields[:bib]
    @key = fields[:key]
  end

  def self.find(id)
    ensure_login do
      bib = {}
      key = id.gsub(/^u/, '')
      response = get("/catalog/bib/key/#{key}",
                    query: REQUEST_PARAMS,
                    headers: auth_headers.merge(TRACKSYS_HEADERS),
                    max_retries: 0
                    )
      check_session(response)

      if response['key'].present? && response['fields'].present?
        return V4::Metadata.new(key: response['key'], bib: response.parsed_response['fields']['bib'])
      else
        # not found
        return nil
      end
    end
  end

  def update_rights params

    marc_856 = {
      tag: "856", inds: "41",
      subfields: [
        {code: 'r', data: params[:uri]},
        {code: 't', data: params[:name]},
        {code: 't', data: params[:statement]},
        {code: 'u', data: params[:resource_uri]},
        {code: 'e', data: '(dpeaa) UVA TrackSys'}
      ]
    }
    # Check for existing 856 from tracksys
    # if a 856 already exists outside of tracksys, add a new one
    existing_856_idx = bib['fields'].index do |f|
      f['tag'] == '856' &&
      f['subfields'].any?{|sub| sub['code'] == 'e' && sub['data'].match?(/UVA TrackSys/i)}
    end


    if existing_856_idx.present?
      # update existing tracksys 856
      bib['fields'][existing_856_idx] = marc_856
    else
      # determine position, just before an existing 856 or immediately higher
      new_idx = bib['fields'].index {|f| f['tag'].to_i >= 856}

      # insert new 856
      if new_idx
        bib['fields'] = bib['fields'].insert(new_idx, marc_856)
      else
        # append to end
        bib['fields'] << marc_856
      end
    end

    # Cleanup leader
    # https://www.oclc.org/bibformats/en/fixedfield/elvl.html
    if bib['leader'][17] =~ /[[:upper:]]/
      bib['leader'][17] = ' '
    end

    updated_record = {
      resource: "/catalog/bib",
      key: key,
      fields: {
        bib: bib
      }
    }
    # send the updated bib
    put_response = self.class.put("/catalog/bib/key/#{key}",
      body: updated_record.to_json,
      headers: self.class.auth_headers.merge(TRACKSYS_HEADERS),
      max_retries: 0
    )
    self.class.check_session(put_response)
    if !put_response.success?
      Rails.logger.error(put_response)
    end

    return put_response
  end
end