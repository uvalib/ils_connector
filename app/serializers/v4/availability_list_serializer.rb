class V4::AvailabilityListSerializer < ActiveModel::Serializer
  has_many :libraries
  has_many :locations
end
