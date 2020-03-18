class V4::LibrarySerializer < ActiveModel::Serializer
  attributes :id, :key, :description, :on_shelf, :non_circulating
end
