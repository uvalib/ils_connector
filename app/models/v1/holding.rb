class V1::Holding
  include ActiveModel::Model
  attr_accessor :catalog_key, :call_number, :call_sequence, :item_id, :shadow, :shelving_key

end
