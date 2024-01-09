require "rails_helper"

RSpec.describe GetSpotTradesJob, type: :job do
  subject { described_class.new }

  describe '#GetSpotTradesJob perform' do
    before do
      ActiveJob::Base.queue_adapter = :test
    end

    it 'should enqeue job' do
      expect {
        described_class.perform_later
      }.to have_enqueued_job(GetSpotTradesJob).on_queue('daily_job')
    end
  end
end
