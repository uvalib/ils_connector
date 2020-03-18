class V4::LocationSerializer < ActiveModel::Serializer
  attributes :id, :key, :description, :on_shelf, :non_circulating, :online, :shadowed
end
