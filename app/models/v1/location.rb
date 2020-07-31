class V1::Location < FirehoseBase


  # gets all locations and returns the XML string
  def self.all
    locations = get("/list/locations", max_retries: 0)
    locations.body
  end

end
