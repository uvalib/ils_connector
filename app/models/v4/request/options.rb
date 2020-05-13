class V4::Request::Options
  include Rails.application.routes.url_helpers

  attr_accessor :list, :availability

  def initialize(availability)
    self.availability = availability
    determine_options
  end

  private
  def determine_options
    self.list = []
    self.list << get_hold_info
    self.list << get_ato_info
    self.list.compact! # remove nil values

    # this.list << other_request_types_go_here
  end

  def get_hold_info
    holdable_items = []

    # Loop through each visible item
    availability.items.each do |item|

      # Add selectable volume options
      if user_can_hold(item) &&
        !item[:unavailable] &&
        item[:volume].present?

        holdable_items << {
          barcode: item[:barcode],
          label: item[:volume]
        }
      end
    end

    # if no Volume options are present, add the first holdable item
    if holdable_items.none?
      holdable_item = availability.items.find do |item|
        user_can_hold(item) && !item[:unavailable]
      end
      if holdable_item
        holdable_items << {
          barcode: holdable_item[:barcode],
          label: holdable_item[:call_number]
        }
      end
    end

    if holdable_items.any?
      return {
        type: :hold,
        sign_in_required: true,
        button_label: "Request items",
        description: '',
        item_options: holdable_items,
        create_url: hold_v4_requests_path
      }
    end
  end

  # LEO users can request on_shelf items
  def user_can_hold item
    if availability.jwt_user[:can_leo]
      return true
    else
      # normal users can only request when not on shelf
      !item[:on_shelf]
    end
  end

  def get_ato_info
    no_ato = availability.items.none? {|item| item[:current_location] == "Available to Order" }
    return if no_ato

    ato_item = {
      catalog_key: availability.title_id,
      isbn: availability.pda_isbn,
      fund_code: availability.fund_code,
      loan_type: availability.loan_type,
      hold_library: availability.pda_hold_library
    }
    return {
      type: :pda,
      sign_in_required: true,
      button_label: "Place Order",
      description: 'This item is available to order.',
      item_options: {},
      create_url: pda_url(params: ato_item)
    }
  end

end