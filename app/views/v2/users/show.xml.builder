xml.instruct!
xml.user do
  xml.barred @user[:barred]
  xml.bursarred
  xml.delinquent
  xml.description
  xml.displayName @user[:displayName]
  xml.email
  xml.givenName
  xml.initials
  xml.libraryGroup
  xml.organizationalUnit
  xml.physicalDelivery
  xml.pin
  xml.preferredLanguage 1
  xml.profile
  xml.statusId @user[:statusType]
  xml.surName
  xml.title
  xml.totalCheckouts @user[:totalCheckouts]
  # user with holds: 115680605
  xml.totalHolds @user[:totalHolds]
  xml.totalOverdue 0
  xml.totalRecalls 1
  # reserve example user: 391414679
  xml.totalReserves 1
  xml.userCats
  xml.computingId @user[:userID]
  xml.sirsiId @user[:userKey]
  xml.key


  #todo render checkout partial
  xml.checkout 

end
