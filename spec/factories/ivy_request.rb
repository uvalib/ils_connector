FactoryBot.define do
  factory :ivy_request, class: V3::IvyRequest do
    sequence(:user_id) {|n| "user#{n}"}
    library { "ALD" }
    sequence(:catalog_id) {|n| "cat#{n}" }
    title { Faker::Book.title }
    sequence(:volume) {|n| "vol#{n}"}
    sequence(:edition) {|n| "#{n.ordinalize} ed."}
    author { Faker::Book.author }
    items do
      [ {barcode: 'X032576506', type: 'test',call: Faker::Internet.ip_v4_address} ]
    end
  end
end
