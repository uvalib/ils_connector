class V1::User < FirehoseBase

  def initialize id
    @user = self.class.get("/users/#{id}", max_retries: 0)
  end


  def to_xml
    # pass body without any parsing
    @user.body
  end

end
