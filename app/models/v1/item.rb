class V1::Item < FirehoseBase

  def initialize id
    @item = self.class.get("/items/#{id}", max_retries: 0)
  end

  def to_xml
    Rails.logger.debug @item
    @item.body
  end

end
