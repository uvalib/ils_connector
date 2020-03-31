class V4::RequestOptionSerializer < ActiveModel::Serializer
  attributes :label, :description, :creation_url
  attribute :errors, if: ->{ object.errors.any? }
end