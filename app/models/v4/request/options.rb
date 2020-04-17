class V4::Request::Options
  include ActionView::Helpers

  attr_accessor :list, :availability

  def initialize(availability)
    self.availability = availability
    determine_options
  end

  private
  def determine_options
    self.list = []
    if hold_info = get_hold_info
      self.list << hold_info
    end

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
        button_label: "Request this unavailable item",
        description: '',
        item_options: holdable_items,
        create_path: Rails.application.routes.url_helpers.hold_v4_requests_path
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

end