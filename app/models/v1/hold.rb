class V1::Hold < FirehoseBase

  attr_accessor :holds

  def initialize user_id
    self.holds = self.class.get("/users/#{user_id}/holds", max_retries: 0)
  end

  def to_xml
    holds.body
  end

end
