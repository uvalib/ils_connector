class V4::Dibs < SirsiBase

  base_uri env_credential(:sirsi_web_services_base)

  # for serializer root node
  def self.model_name
    'dibs'
  end

  def self.set_in_dibs( barcode )
    {}
  end

  def self.set_no_dibs( barcode )
    {}
  end

  #private

end
