class V4::Request::Options
  include Rails.application.routes.url_helpers

  attr_accessor :list, :availability, :holdable_items

  def initialize(availability)
    self.availability = availability
    determine_options
  end

  private
  def determine_options
    determine_holdable_items
    self.list = []
    self.list << get_hold_info
    self.list << get_scan_info
    self.list << get_ato_info
    self.list.compact! # remove nil values

    # this.list << other_request_types_go_here
  end

  def get_hold_info
    if holdable_items.any?
      return {
        type: :hold,
        sign_in_required: true,
        button_label: "Request items",
        description: 'Request an unavailable item or request LEO delivery.',
        item_options: holdable_items
      }
    end
  end

  # Scans use the same holdable items list
  def get_scan_info
    if holdable_items.any?
      return {
        type: :scan,
        sign_in_required: true,
        button_label: "Request a scan",
        description: 'Select a portion of this item to be scanned.',
        item_options: holdable_items
      }
    end
  end

  def determine_holdable_items
    self.holdable_items = []

    # Loop through each visible item
    availability.items.each do |item|

      # Add selectable volume options
      if holdable_item?(item) &&
        item[:volume].present?

        self.holdable_items << {
          barcode: item[:barcode],
          label: item[:volume],
          library: item[:library_id]
        }
      end
    end

    # if no Volume options are present, add the first holdable item
    if holdable_items.none?
      holdable_item = availability.items.find do |item|
        holdable_item?(item)
      end
      if holdable_item
        self.holdable_items << {
          barcode: holdable_item[:barcode],
          label: holdable_item[:call_number],
          library: holdable_item[:library_id]
        }
      end
    end
  end

  def holdable_item? item
    user_can_hold(item) &&
    !item[:unavailable] &&
    item[:current_location] != "Available to Order" &&
    item[:library] != "Special Collections"
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


  HTTP_ERRORS = [
    EOFError,
    Errno::ECONNRESET,
    Errno::ECONNREFUSED,
    Errno::EINVAL,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError,
    Timeout::Error,
  ]

  def get_ato_info
    no_ato = availability.items.none? {|item| item[:current_location] == "Available to Order" }
    return nil if no_ato

    # check if there is already an order
    begin
      pda = HTTParty.get("#{env_credential(:pda_base_url)}/check/#{availability.title_id}",
                          headers: {authorization: availability.jwt_user[:auth_token]})

      if pda.not_found?
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
          button_label: I18n.t('requests.pda.button_label'),
          description: I18n.t('requests.pda.description'),
          item_options: [],
          create_url: pda_url(params: ato_item)
        }
      elsif pda.success?
        # An order has already been made
        return nil
      else
        # error
        Rails.logger.error("PDA error: #{pda.response.body}")
        return nil
      end
    rescue *HTTP_ERRORS => e
      Rails.logger.error("PDA error: #{e}")
      return nil
    end
  end
end