module XmlHelpers
  extend ActiveSupport::Concern

  def xml_for xml, obj, method
    xml.send(:method, obj.send(:method))
  end
end
