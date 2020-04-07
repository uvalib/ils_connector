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

    self.list << get_hold_info

    # this.list << other_request_types
  end

  def get_hold_info
    holdable_items = []

    # Loop through each visible item
    availability.items.each do |item|

      # Add selectable volume options
      if !item[:on_shelf] &&
        !item[:volume].present? &&
        !item[:unavailable]

        holdable_items << {
          itemBarcode: item[:barcode],
          label: item[:volume]
        }
      end
    end

    # if no Volume options are present, add the first holdable item
    if holdable_items.none?
      holdable_item = availability.items.find do |item|
        !item[:on_shelf] && !item[:unavailable]
      end
      if holdable_item
        holdable_items << {
          itemBarcode: holdable_item[:barcode]
        }
      end
    end

    if holdable_items.any?
      return {
        type: :hold,
        button_label: "Request this unavailable item",
        description: '',
        item_options: holdable_items,
        create_path: Rails.application.routes.url_helpers.hold_v4_requests_path
      }
    end
  end

end