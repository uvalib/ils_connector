class V1::HoldingSerializer < ActiveModel::Serializer
  type :holding
  has_many :copies, key: :physical_item
  has_one :library
  attributes :catalog_key, :call_number, :call_sequence, :item_id, :shadow, :shelving_key
end
