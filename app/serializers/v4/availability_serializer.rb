class V4::AvailabilitySerializer < ActiveModel::Serializer
  attributes :title_id
  has_many :columns do
    V4::Availability::VISIBLE_FIELDS.values
  end
  has_many :items
end
