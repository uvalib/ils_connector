FactoryBot.define do
  factory :api_user do
    email Faker::Internet.email
    password 'password'
  end
end
