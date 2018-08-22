class V2::IvyRequest < ApplicationRecord
  include AASM

  validates_presence_of :user_id, :library, :catalog_id, :items

  VALID_ITEM_KEYS = %w(barcode type call)
  validate :valid_item_keys, if: :items?
  before_save :cleanup_item_keys


  aasm :state do
    state :created, initial: true
    # more to come
  end


  private

  def valid_item_keys
    if !items.is_a? Array
      self.errors.add(:items, "must be an array of hash(s).")
      return false
    end
    items.each do |item|

      item_keys = item.keys
      if (VALID_ITEM_KEYS - item_keys).empty?
        return true
      else
        self.errors.add(:items, "valid keys are #{VALID_ITEM_KEYS.to_sentence}. Given: #{item_keys}")
        return false
      end
    end
  end

  def cleanup_item_keys
    self.items.each {|item| item.keep_if {|k,v| VALID_ITEM_KEYS.include?(k)} }
  end
end
