class V1::Reserve < FirehoseBase

  attr_accessor :reserves

  def initialize user_id
    self.reserves = self.class.get("/users/#{user_id}/reserves")
  end

  def to_xml
    reserves.to_xml
  end

end
