class V2::Library < ActiveYaml::Base

  set_root_path "app/data/"
  set_filename "libraries"

  class <<self
    alias_method :all_yaml, :all
    alias_method :find_by_yaml, :find_by
  end

  # store libraries in memory. ActiveYaml has thread issues
  def self.all
    @@libraries ||= all_yaml
  end
  def self.find_by opt
    all
    key = opt.first.first
    value = opt.first.last
    library = @@libraries.find {|l| l.send(key) == value}
    library
  end
end
