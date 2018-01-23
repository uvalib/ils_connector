class V1::Item < FirehoseBase

  def initialize id
    @item = self.class.get("/items/#{id}")
  end

  def to_xml
    @item.to_xml
  end

end
