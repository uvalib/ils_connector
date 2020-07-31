class V1::FirehoseLibrary < FirehoseBase

  def self.all
    libraries = get("/list/libraries", max_retries: 0)
    libraries.body
  end

end
