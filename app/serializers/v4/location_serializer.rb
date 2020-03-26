class V4::LocationSerializer < ActiveModel::Serializer
  attributes :id, :key, :description, :online, :shadowed, :on_shelf, :circulating
end
