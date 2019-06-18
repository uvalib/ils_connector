class V1::FirehoseLibrary < FirehoseBase

  def self.all
    libraries = get("/list/libraries")
    libraries.body
  end

end
