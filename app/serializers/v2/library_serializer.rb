class V2::LibrarySerializer < ActiveModel::Serializer
  root :libraries
  type :library
  attributes :id, :code, :name, :holdable, :deliverable, :remote

end
