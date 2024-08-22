# This loads and exposes app/data/non_circulating.yml and app/data/on_shelf.yml config
module AvailabilityHelper
  extend ActiveSupport::Concern
  require 'yaml'
  @@on_shelf = []
  @@non_circulating = []

  def self.on_shelf_library? lib
    self.load
    @@on_shelf['libraries'].any? lib
  end
  def self.on_shelf_location? loc
    self.load
    @@on_shelf['locations'].any? loc
  end
  def self.non_circulating_library? lib
    self.load
    @@non_circulating['libraries'].any? lib
  end
  def self.non_circulating_location? loc
    self.load
    @@non_circulating['locations'].any? loc
  end


  private
  def self.load
    unless @@on_shelf.present?
      Rails.logger.info 'Loading On Shelf data'
      @@on_shelf = YAML.load_file('app/data/on_shelf.yml')
    end
    unless @@non_circulating.present?
      Rails.logger.info 'Loading Non Circulating data'
      @@non_circulating = YAML.load_file('app/data/non_circulating.yml')
    end
  end
end
