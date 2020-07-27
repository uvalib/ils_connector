require 'rails_helper'

RSpec.describe "V4::Availability", type: :request do
  describe "GET /v4/availability/:id" do
    let(:title_id) {'4684522'}
    before do
      get v4_availability_path(id: title_id, format: :json), headers: {'ACCEPT': 'application/json'}
    end

    it 'works' do
      expect(response).to have_http_status(200)
    end

    it 'contains the correct keys' do

      v4_response = JSON.parse(response.body)['availability']

      expect(v4_response.keys).to match_array(%w(title_id columns items request_options))

      v4_response['items'].each do |item|
        item['fields'].each do |field|
          expect(field.keys).to match_array(%w(name value visible type))
        end
      end
    end
  end
  describe "Medium Rare Notice" do

    let(:title_id) {'7018337'}
    before do
      get v4_availability_path(id: title_id, format: :json), headers: {'ACCEPT': 'application/json'}
    end

    it 'includes the notice' do
      items = JSON.parse(response.body)['availability']['items']
      items.each do |i|
        if i.has_key? 'notice'
          expect(i['notice']).to eq(V4::Location::MEDIUM_RARE_MESSAGE)
        end
      end

    end
  end
end
