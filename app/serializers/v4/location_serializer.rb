class V4::LocationSerializer < ActiveModel::Serializer
  attributes :id, :key, :description, :on_shelf, :hidden
end
