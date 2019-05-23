class V1::Location < FirehoseBase


  # gets all locations and returns the XML string
  def self.all
    locations = get("/list/locations")
    locations.body
  end

end
