require 'rails_helper'

RSpec.describe AggregateTxSnapshotInfo, type: :model do
  let(:snapshot_info) { create(:aggregate_tx_snapshot_info) }

  it "have a valid factory" do
    expect(snapshot_info).to be_valid
  end
end
