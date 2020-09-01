class V4::AvailabilitySerializer < ActiveModel::Serializer
  attributes :title_id
  has_many :columns do
    V4::Availability::VISIBLE_FIELDS.keys
  end
  has_many :items
  has_many :request_options
  has_many :bound_with
end
