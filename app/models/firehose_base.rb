class FirehoseBase
  include HTTParty
  base_uri env_credential(:firehose_base_url)
  format :xml
  default_timeout 1

end
