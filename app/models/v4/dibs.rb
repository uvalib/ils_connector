class V4::Dibs < SirsiBase

  include ActiveModel::Validations
  base_uri env_credential(:sirsi_web_services_base)

  attr_accessor :barcode, :item_data, :put_data, :fields, :key, :custom_dibs_info, :item_type, :not_found

  DIBS_LOCATION_KEY = "DIBS".freeze
  DIBS_ITEM_TYPE_KEY = "DIBS".freeze
  DIBS_CUSTOM_INFO_KEY = "DIBS-INFO".freeze



  def self.set_in_dibs( barcode )
    dibs_item = self.new(barcode)
    return dibs_item if dibs_item.errors.any?

    if dibs_item.custom_dibs_info.present? && dibs_item.item_type == DIBS_LOCATION_KEY
      Rails.logger.warn "Item already in DIBS. No changes made. Barcode: #{dibs_item.barcode}"
      return dibs_item
    end

    dibs_custom_field = {
      "resource": "/catalog/item/customInformation",
      "fields": {
        "itemExtendedInformation": {
          "resource": "/policy/itemExtendedInformation",
          "key": DIBS_CUSTOM_INFO_KEY
        },
        # For restoring later, custom data to the item's previous location and item type.
        "data": {"currentLocation": dibs_item.fields['currentLocation'], "itemType": dibs_item.fields['itemType']}.to_json
      }
    }
    dibs_item.put_data['fields']['currentLocation']['key'] = DIBS_LOCATION_KEY
    dibs_item.put_data['fields']['itemType']['key'] = DIBS_ITEM_TYPE_KEY
    dibs_item.put_data['fields']['customInformation'] << dibs_custom_field

    ensure_login do
      response = put("/catalog/item/key/#{dibs_item.key}",
        body: dibs_item.put_data.to_json,
        headers: auth_headers.merge('SD-Prompt-Return': nil, 'x-sirs-clientID': 'DIBS-STAFF'),
        max_retries: 0
      )
      check_session(response)
      if !response.success?
        Rails.logger.warn "Sirsi PUT Failed for #{dibs_item.barcode}: #{response.body}"
        dibs_item.errors.add(:sirsi, response.body)
      end

    end
    return dibs_item
  end


  def self.set_no_dibs( barcode )
    dibs_item = self.new(barcode)
    return dibs_item if dibs_item.errors.any?

    if !dibs_item.custom_dibs_info.present? && dibs_item.item_type != DIBS_LOCATION_KEY
      Rails.logger.warn "Item not at DIBS location. No changes made. Barcode: #{dibs_item.barcode}"
      return dibs_item
    end

    if dibs_item.custom_dibs_info.present?
      # restore original current location and item type
      original_fields = JSON.parse( dibs_item.custom_dibs_info['fields']['data'] )
      dibs_item.put_data['fields']['currentLocation'] = original_fields['currentLocation']
      dibs_item.put_data['fields']['itemType'] = original_fields['itemType']

      # remove DIBS custom info
      original_custom_information = dibs_item.put_data['fields']['customInformation'].reject do |custom_info|
        custom_info['fields']['itemExtendedInformation']['key'] == DIBS_CUSTOM_INFO_KEY
      end
      dibs_item.put_data['fields']['customInformation'] = original_custom_information
    end

    ensure_login do
      Rails.logger.info dibs_item.put_data.to_json

      response = put("/catalog/item/key/#{dibs_item.key}",
        body: dibs_item.put_data.to_json,
        headers: auth_headers.merge('SD-Prompt-Return': nil, 'x-sirs-clientID': 'DIBS-STAFF'),
        max_retries: 0
      )
      check_session(response)

      if !response.success?
        Rails.logger.warn "Sirsi PUT Failed for #{dibs_item.barcode}: #{response.body}"
        dibs_item.errors.add(:sirsi, response.body)
      end
    end
    return dibs_item

  end

  def initialize(barcode)
    @barcode = barcode
    get_dibs_item_data
  end


  def get_dibs_item_data
    self.class.ensure_login do
      params = {
         includeFields: "*,customInformation{*}",
         json: true
      }
      response = self.class.get("/catalog/item/barcode/#{barcode}",
         query: params,
         headers: self.class.auth_headers,
         max_retries: 0
      )
      self.class.check_session(response)
      barcode_check = response.dig('fields', 'barcode')
      if barcode_check.blank?
         Rails.logger.warn "DIBS Barcode Not Found: #{barcode}"
         self.errors.add(:not_found, "Barcode #{barcode}")
         return
      end
      self.item_data = response.parsed_response
      self.put_data = item_data.deep_dup
      self.fields = item_data['fields']
      self.key = item_data['key']
      self.item_type = fields['itemType']['key']

      self.custom_dibs_info = fields['customInformation'].find do |ci|
        ci['fields']['itemExtendedInformation']['key'] == DIBS_CUSTOM_INFO_KEY
      end
    end
  end

end
