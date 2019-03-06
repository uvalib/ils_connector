xml.instruct!
xml.user do
  xml.barred @user.data[:barred]
  xml.bursarred
  xml.delinquent
  xml.description
  xml.displayName @user.data[:displayName]
  xml.email
  xml.givenName
  xml.initials
  xml.libraryGroup
  xml.organizationalUnit
  xml.physicalDelivery
  xml.pin
  xml.preferredLanguage 1
  xml.profile
  xml.statusId @user.data[:statusType]
  xml.surName
  xml.title
  xml.totalCheckouts @user.data[:totalCheckouts]
  # user with holds: 115680605
  xml.totalHolds @user.data[:totalHolds]
  xml.totalOverdue 0
  xml.totalRecalls 1
  # reserve example user: 391414679
  xml.totalReserves 1
  xml.userCats
  xml.computingId @user.data[:userID]
  xml.sirsiId @user.data[:userKey]
  xml.key


  #todo render checkout partial
  xml.checkout 

end
