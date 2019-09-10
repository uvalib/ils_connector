xml.instruct!
xml.user computingId: @user[:alternateID], sirsiId: @user[:barcode], key: @user[:key] do
  xml.barred @user[:standing][:key] == 'BARRED'
  xml.bursarred false
  xml.delinquent false
  xml.description @user[:description].try(:first)
  xml.displayName @user[:display_name]
  xml.email @user[:email]
  xml.givenName @user[:first_name]
  xml.initials @user[:initials]
  xml.surName @user[:last_name]
  xml.title @user[:title].try(:first)
  xml.libraryGroup 0
  xml.organizationalUnit @user[:department].try(:first)
  xml.physicalDelivery @user[:office].try(:first)
  xml.pin @user[:pin]
  xml.preferredlanguage 1
  xml.profile @user[:profile][:key].titleize
  xml.statusId nil
  xml.totalCheckouts @user['patronCirculationInfo']['numberOfCheckouts']
  # user with holds: 115680605
  xml.totalHolds @user['patronCirculationInfo']['numberOfHolds']
  xml.totalOverdue @user['patronCirculationInfo']['estimatedOverdues']
  xml.totalRecalls @user['patronCirculationInfo']['numberOfRecalls']
  # reserve example user: 391414679
  xml.totalReserves  @user['totalReserves']
  xml.userCats nil


  # CircRecord == Checkout
  @user['patronCheckoutInfo'].each do |circ_record|
    render partial: 'circ_record', locals: {builder: xml, circ_record: circ_record}
  end

  @user['patronHoldInfo'].each do |hold|
    render partial: 'v2/holds/show', locals: {builder: xml, hold: hold}
  end

 @user['courseReserves'].each do |course|
   render partial: 'course_reserves', locals: {builder: xml, course: course}
 end



end
