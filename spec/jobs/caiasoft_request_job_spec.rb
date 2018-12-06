require 'rails_helper'

RSpec.describe CaiasoftRequestJob, type: :job do
  include ActiveJob::TestHelper

  before do
    @ivy_request = create(:ivy_request)
  end

  after do
    clear_enqueued_jobs
  end

  describe "new request" do
    it 'queues a job' do
      CaiasoftRequestJob.perform_later @ivy_request
      assert_enqueued_jobs 1
    end

    it 'receives a successful response' do
      pending 'Need to finish'
      CaiasoftRequestJob.perform_now @ivy_request
      expect(@ivy_request.reload.state).to eq(V3::IvyRequest::STATE_SUCCESS.to_s)
    end

    it 'errors with an invalid library stop' do
      @ivy_request.library = "INVALID"
      CaiasoftRequestJob.perform_now @ivy_request
      expect(@ivy_request.reload.state).to eq(V3::IvyRequest::STATE_ERROR.to_s)
    end
  end

end
