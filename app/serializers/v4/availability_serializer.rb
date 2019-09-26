class V4::AvailabilitySerializer < ActiveModel::Serializer
  attributes :title_id
  has_many :columns do
    V4::Availability::COLUMNS.values
  end
  has_many :holdings
end
