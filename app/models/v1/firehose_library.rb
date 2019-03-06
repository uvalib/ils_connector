class V1::FirehoseLibrary < FirehoseBase

  attr_accessor :libraries

  def initialize
    self.libraries = self.class.get("/list/libraries")
  end

  def to_xml
    libraries.body
  end

end
