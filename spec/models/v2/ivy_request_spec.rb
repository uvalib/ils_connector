require 'rails_helper'

RSpec.describe V2::IvyRequest, type: :model do

  subject {build(:ivy_request)}

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without a user id" do
    subject.user_id = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without a library" do
    subject.library = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without a catalog id" do
    subject.catalog_id = nil
    expect(subject).to_not be_valid
  end

  it "is not valid without a least one item" do
    subject.items = nil
    expect(subject).to_not be_valid
    subject.items = []
    expect(subject).to_not be_valid
  end

  describe 'items' do

    it 'must be an array' do
      subject.items = {barcode: '1234', type: 'test', call: '12345'}
      expect(subject).to_not be_valid
    end

    it 'must contain the correct keys' do
      subject.items = [{barcode: '1234', type: 'test', call: '12345'}]
      expect(subject).to be_valid
      subject.items = [{bad: '1234', type: 'test', call: '12345'}]
      expect(subject).to_not be_valid
    end

    it 'removes invalid keys on save' do
      subject.items.first < {bad: '1234'}
      expect(subject).to be_valid
      subject.save
      expect(subject).to be_valid

      item_keys = subject.items.first.keys
      expect(item_keys).to match_array V2::IvyRequest::VALID_ITEM_KEYS
    end
  end
end
