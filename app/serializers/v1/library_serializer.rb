class V1::LibrarySerializer < ActiveModel::Serializer
  type :library
  attributes :id, :code, :name, :holdable, :deliverable, :remote

end
