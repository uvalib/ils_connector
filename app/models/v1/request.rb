class V1::Request < FirehoseBase

  attr_accessor :request

  def initialize request_params
    self.request = self.class.post("/requests/renewAll", params: request_params)
  end

  def to_xml
    request.to_xml
  end

end
