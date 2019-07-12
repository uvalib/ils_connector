class V2::ItemType < SirsiBase
  base_uri env_credential(:sirsi_web_services_base)

  REQUEST_PARAMS = {key: '*', includeFields: '*'}

  def self.all
    raw = get('/v1/policy/itemType/simpleQuery',
              query: REQUEST_PARAMS,
              headers: auth_headers
    )

    @@items = []
    raw.each do |i|
      @@items << i['fields']
    end
    @@holdable ||= get_holdable
    @@items
  end

  def self.get_holdable 
    holdable = {}
    csv_text = File.read("app/data/firehose_item_types.csv")
    CSV.parse(csv_text, headers: true).each do |row|
      holdable[row[0].to_i] = row[3].to_i > 0
    end
    return holdable
  end

  def self.holdable?(policy_num) 
    @@holdable ||= get_holdable
    if @@holdable[policy_num.to_i]
      Rails.logger.info("Item type #{policy_num} is holdable")
      return true
    end

    Rails.logger.info("Item type #{policy_num} is NOT holdable")
    return false
  end

  def self.find(key = 'policyNumber', value)
    unless defined?(@@items)
      all
    end

    @@items.find {|i| i[key] == value}
  end
end
