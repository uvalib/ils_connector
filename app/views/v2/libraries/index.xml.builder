xml.instruct!
xml.libraries do
  @libraries.each do |lib|
    xml.library do
      xml.id lib.id
      xml.code lib.code
      xml.remote lib.remote
      xml.name lib.name
      xml.holdable lib.holdable
      xml.deliverable lib.deliverable
    end
  end
end
