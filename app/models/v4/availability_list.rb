class V4::AvailabilityList < ActiveModelSerializers::Model
  attributes :libraries, :locations

  def libraries
    V4::Library.all
  end
  def locations
    V4::Location.all
  end

  def self.model_name
    "availability_list"
  end

end
