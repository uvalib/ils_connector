class V1::Checkout < FirehoseBase

  attr_accessor :checkouts

  def initialize user_id
    self.checkouts = self.class.get("/users/#{user_id}/checkouts", max_retries: 0)
  end

  def to_xml
    checkouts.body
  end

end
