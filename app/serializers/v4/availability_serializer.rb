class V4::AvailabilitySerializer < ActiveModel::Serializer
  attributes :title_id
  has_many :holdings
end
