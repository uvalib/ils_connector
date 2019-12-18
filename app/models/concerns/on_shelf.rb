module OnShelf
  extend ActiveSupport::Concern
  require 'yaml'
  @@on_shelf = []

  def self.library? lib
    self.load
    @@on_shelf['libraries'].any? lib
  end
  def self.location? loc
    self.load
    @@on_shelf['libraries'].any? loc
  end

  private
  def self.load
    unless @@on_shelf.present?
      Rails.logger.info 'Loading On Shelf data'
      puts 'loading'
      @@on_shelf = YAML.load_file('app/data/on_shelf.yml')
    end
  end
end
