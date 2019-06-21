class V2::Library < ActiveYaml::Base
  include ActiveModel::Serializers::Xml


  set_root_path "app/data/"
  set_filename "libraries"
end
