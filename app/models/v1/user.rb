class V1::User < FirehoseBase

  def initialize id
    @user = self.class.get("/users/#{id}")
  end


  def to_xml
    # pass body without any parsing
    @user.body
  end

end
