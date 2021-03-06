require 'rails_helper'

RSpec.describe "V2::Users", type: :request do

  before { skip "Deprecated"}
  describe "GET /v2/users/:id" do

    let(:user_id) { 'mhw8m' }

    before do
      get v2_user_path(id: user_id, format: :xml), headers: {'ACCEPT': 'application/xml'}
    end

    it "works" do
      expect(response).to have_http_status(200)
    end

    it 'matches the firehose response' do
#      firehose_response = V1::User.new(user_id)

      v2_response = Nokogiri::XML(response.body) do |config|
        config.noblanks
      end

      expect(v2_response.root.name).to eq('user')
      user = v2_response.at_css('user')
      attributes = user.attributes.keys
      expect(attributes).to include('computingId', 'sirsiId', 'key')

      # expect the base list of attributes to be present
      # does not include checkouts holds or course_reserves
      user_fields.each do |field|
        node = user.at_css field
        expect(node).to be_present
        #expect(node.text).to be_present
      end


    end

    def user_fields
      %w(barred
        bursarred
        delinquent
        description
        displayName
        email
        givenName
        initials
        libraryGroup
        organizationalUnit
        physicalDelivery
        pin
        preferredlanguage
        profile
        statusId
        surName
        title
        totalCheckouts
        totalHolds
        totalOverdue
        totalRecalls
        totalReserves
        userCats
      )
    end
  end
end
