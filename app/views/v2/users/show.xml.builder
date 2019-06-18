xml.instruct!
xml.user computingId: @user[:alternateID], sirsiId: @user[:barcode], key: @user[:key] do
  xml.barred @user[:barred]
  xml.bursarred false
  xml.delinquent false
  xml.description @user[:description].first
  xml.displayName @user[:display_name]
  xml.email @user[:email]
  xml.givenName @user[:first_name]
  xml.initials @user[:initials]
  xml.surName @user[:last_name]
  xml.title @user[:profile][:title]
  xml.libraryGroup 0
  xml.organizationalUnit @user[:department]
  xml.physicalDelivery @user[:office]
  xml.pin @user[:pin]
  xml.preferredlanguage 1
  xml.profile @user[:profile][:key]
  xml.statusId 
  xml.totalCheckouts @user[:totalCheckouts]
  # user with holds: 115680605
  xml.totalHolds @user[:totalHolds]
  xml.totalOverdue 0
  xml.totalRecalls 1
  # reserve example user: 391414679
  xml.totalReserves 1
  xml.userCats


  #todo render checkout partial
  #xml.checkout 

end
