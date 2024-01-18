class AddLastTradeAtToCombineTxSnapshotRecords < ActiveRecord::Migration[6.1]
  def change
    add_column :combine_tx_snapshot_records, :last_trade_at, :datetime
  end
end
