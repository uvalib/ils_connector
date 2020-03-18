class V4::RequestOptionSerializer < ActiveModel::Serializer
  attributes :steps
  attribute :errors, if: ->{ object.errors.any? }
end