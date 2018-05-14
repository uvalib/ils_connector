class V1::Checkout < FirehoseBase

  attr_accessor :checkouts

  def initialize user_id
    self.checkouts = self.class.get("/users/#{user_id}/checkouts")
  end

  def to_xml
    checkouts.to_xml
  end

end
