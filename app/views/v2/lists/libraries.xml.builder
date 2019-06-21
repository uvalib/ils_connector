xml.instruct!
xml.libraries do
  @libraries.each do |lib|
    render(partial: 'v2/lists/library', locals: {builder: xml, lib: lib })
  end
end
