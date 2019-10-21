module Refreshable
  extend ActiveSupport::Concern

  # This concern implements a consistent refresh mechanism for API responses that don't change much.
  # Before making an api call check `Model.time_to_refresh?`
  # after receiving and storing the response, run `Model.reset_refresh_timer`

  REFRESH_INTERVAL = 1.day
  REFRESH_TIME = '3am'
  REFRESH_ZONE = 'Eastern Time (US & Canada)'

  module ClassMethods
    # next update is unique to each model and allows them to be updated independently.
    attr_accessor :next_update

    def time_to_refresh?
      return true unless next_update
      Time.current.in_time_zone(REFRESH_ZONE) >= next_update
    end

    def reset_refresh_timer
      self.next_update = Time.parse(REFRESH_TIME).in_time_zone(REFRESH_ZONE) + REFRESH_INTERVAL
      Rails.logger.info "Refreshed #{self.name}. Next update: #{next_update}"
    end
  end
end
