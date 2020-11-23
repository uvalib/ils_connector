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
    self.list << get_video_reserve_info

    self.list << get_ato_info
    self.list.compact! # remove nil values

    # this.list << other_request_types_go_here
  end

  def get_hold_info
    if holdable_items.any?
      return {
        type: :hold,
        sign_in_required: true,
        button_label: "Request item",
        description: 'Request an unavailable item or request delivery.',
        item_options: holdable_items
      }
    end
  end

  # Scans use the same holdable items list
  def get_scan_info
    scan_items = holdable_items.reject {|item| item[:is_video]}
    if scan_items.any? && availability.jwt_user[:home_library] != "HEALTHSCI"

      return {
        type: :scan,
        sign_in_required: true,
        button_label: "Request a scan",
        description: 'Select a portion of this item to be scanned.',
        item_options: scan_items
      }
    end
  end

  def get_video_reserve_info
    video_items = holdable_items.select {|item| item[:is_video]}
    if video_items.any? && availability.jwt_user[:can_place_reserve]
      return {
        type:             :videoReserve,
        button_label:     "Video reserve request",
        sign_in_required: true,
        description:      "Request a video reserve for streaming",
        item_options:     video_items
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
          library: item[:library_id],
          location: item[:current_location],
          location_id: item[:current_location_id],
          is_video: item[:is_video],
          notice: item[:notice]
        }
      end
    end

    # if no Volume options are present, add the first holdable item
    if holdable_items.none?
      item = availability.items.find do |i|
        holdable_item?(i)
      end
      if item.present?
        self.holdable_items << {
          barcode: item[:barcode],
          label: item[:call_number],
          library: item[:library_id],
          location: item[:current_location],
          location_id: item[:current_location_id],
          is_video: item[:is_video],
          notice: item[:notice]
        }
      end
    end
  end

  def holdable_item? item
    user_can_hold(item) &&
    !item[:unavailable] &&
    !item[:non_circulating]
  end

  # LEO users can request on_shelf items
  def user_can_hold item
    # For now all users and can request on shelf items
    return true

    #if availability.jwt_user[:can_leo]
    #  return true
    #else
    #  # normal users can only request when not on shelf
    #  !item[:on_shelf]
    #end
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
    ato_item = availability.items.find {|item| item[:current_location] == "Available to Order" }
    return nil if !ato_item

    # check if there is already an order
    begin
      pda = HTTParty.get("#{env_credential(:pda_base_url)}/check/#{availability.title_id}",
                          headers: {authorization: availability.jwt_user[:auth_token]}, max_retries: 0)

      if pda.not_found?
        ato_item = {
          catalog_key: availability.title_id,
          isbn: availability.pda_isbn,
          barcode: ato_item[:barcode],
          title: availability.title,
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
        # return just the description
        return {
          type: :pda,
          sign_in_required: true,
          description: I18n.t('requests.pda.pending_description'),
          item_options: [],
        }
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
