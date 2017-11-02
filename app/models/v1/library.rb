class V1::Library < ActiveYaml::Base
  include ActiveModel::Serialization

  set_root_path "app/data/"
  set_filename "libraries"

end
