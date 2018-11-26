class V3::IvyRequest < ApplicationRecord
  include AASM

  validates_presence_of :user_id, :library, :catalog_id, :items

  REQUIRED_ITEM_KEYS = %w(barcode type call)
  OPTIONAL_ITEM_KEYS = %w(errors)
  VALID_ITEM_KEYS    = REQUIRED_ITEM_KEYS + OPTIONAL_ITEM_KEYS

  validate :valid_item_keys, if: :items?
  before_save :cleanup_item_keys


  aasm :state do
    state :created, initial: true
    state :error
    state :success

    event :errored do
      transitions from: [:created, :sent], to: :error
    end
    event :request_sent do
      transitions from: [:created, :error], to: :success
    end
  end


  private

  # Check for array and required item keys. Other item validations should go here.
  def valid_item_keys
    if !items.is_a? Array
      self.errors.add(:items, "must be an array of hash(s).")
      return false
    end
    items.each do |item|

      item_keys = item.keys
      if (REQUIRED_ITEM_KEYS - item_keys).empty?
        return true
      else
        self.errors.add(:items, "required item keys are #{REQUIRED_ITEM_KEYS.to_sentence}. Given: #{item_keys}")
        return false
      end
    end
  end

  def cleanup_item_keys
    self.items.each {|item| item.keep_if {|k,v| VALID_ITEM_KEYS.include?(k)} }
  end
end
