require 'rails_helper'

RSpec.describe AggregateTxSnapshotRecord, type: :model do
  let(:snapshot) { create(:aggregate_tx_snapshot_record) }

  it "have a valid factory" do
    expect(snapshot).to be_valid
  end
end
