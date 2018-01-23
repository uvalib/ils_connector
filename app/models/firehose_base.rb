class FirehoseBase
  include HTTParty
  base_uri "http://firehose2.lib.virginia.edu:8081/firehose2"
  format :xml

end
