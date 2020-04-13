class V4::HoldSerializer < ActiveModel::Serializer
  attributes :pickup_library, :item_barcode, :user_id

  attribute( :errors, if: ->{ object.errors.any? }) do
    object.errors.full_messages
  end
end
