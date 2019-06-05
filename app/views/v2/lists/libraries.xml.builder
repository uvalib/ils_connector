xml.instruct!
xml.libraries do
  @libraries.each do |lib|
    xml.library code: lib.code, id: lib.id do
      xml.remote lib.remote
      xml.name lib.name
      xml.holdable lib.holdable
      xml.deliverable lib.deliverable
    end
  end
end
