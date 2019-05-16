FactoryBot.define do
  factory :v2_user do
    barred { false }
    bursarred { false }
    delinquent { false }
    description { "Test" }
    displayName { Faker::Name.name_with_middle }
    email { Faker::Internet.email }
    givenName { Faker::Name.first_name }
    initials { Faker::Name.initials(1) }
    libraryGroup { 0 }
    organizationalUnit { 'Test' }
    physicalDelivery { '160 Mccormick Charlottesville, VA 22904 United States of America' }
    pin { Faker::Number.number(4) }
    preferredLanguage { 1 }
    profile { 'Faculty' }
    statusId { 2 }
    surName { Faker::Name.last_name }
    title { Faker::Job.title }
    totalCheckouts { 0 }
    totalHolds { 0 }
    totalOverdue { 0 }
    totalRecalls { 0 }
    totalReserves { 0 }
    userCats { Hash.new({catCode: 2, catValue: 10}) }
    computingId { 'naw4t' }
    sirsiId { Faker::Number.number(7) }
    key { Faker::Number.number(5) }

  end
end
