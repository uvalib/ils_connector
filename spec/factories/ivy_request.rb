FactoryBot.define do
  factory :ivy_request, class: V2::IvyRequest do
    sequence(:user_id, ) {|n| "user#{n}"}
    library {"Alderman"}
    sequence(:catalog_id) {|n| "cat#{n}" }
    title { Faker::Book.title }
    sequence(:volume) {|n| "vol#{n}"}
    sequence(:edition) {|n| "#{n.ordinalize} ed."}
    author { Faker::Book.author }
    items do
      [ {barcode: Faker::Number.number(12), type: 'test',call: Faker::Internet.ip_v4_address} ]
    end
  end
end
