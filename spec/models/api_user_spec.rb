require 'rails_helper'

RSpec.describe ApiUser, type: :model do

  it 'has a valid factory' do
    expect(FactoryBot.create(:api_user)).to be_valid
  end
end
