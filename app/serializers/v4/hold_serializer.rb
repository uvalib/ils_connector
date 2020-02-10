class V4::HoldSerializer < ActiveModel::Serializer
  attribute :errors, if: ->{ object.errors.any? }


end
