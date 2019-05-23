xml.instruct! :xml, encoding: 'UTF-8', standalone: 'yes'
xml.locations do
  @locations.each do |loc|
    xml.location code: loc['displayName'], id: loc['policyNumber'] do
      xml.name loc['description']
    end
  end
end
