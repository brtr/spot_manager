class GenerateAggregateTransactionsSnapshotsJob < ApplicationJob
  queue_as :daily_job

  def perform(date: Date.today)
    transactions_snapshot_info = AggregateTxSnapshotInfo.where(event_date: date).first_or_create

    generate_snapshot(transactions_snapshot_info)

    ForceGcJob.perform_later
  end

  private

  def generate_snapshot(transactions_snapshot_info)
    txs = AggregateTransaction.all

    txs.find_each(batch_size: 100) do |tx|
      AggregateTxSnapshotInfo.transaction do
        transactions_snapshot_record = transactions_snapshot_info.aggregate_tx_snapshot_records.find_or_initialize_by(
          original_symbol: tx.original_symbol,
          from_symbol: tx.from_symbol,
          to_symbol: tx.to_symbol,
          fee_symbol: tx.fee_symbol
        )

        # 更新快照记录
        transactions_snapshot_record.update(
          qty: tx.qty,
          price: tx.price,
          fee: tx.fee,
          amount: tx.amount,
          current_price: tx.current_price,
          revenue: tx.revenue,
          roi: tx.roi,
          percentage_24h: tx.percentage_24h,
          percentage_7d: tx.percentage_7d,
          last_trade_at: tx.last_trade_at
        )
      end
    end
  end
end
