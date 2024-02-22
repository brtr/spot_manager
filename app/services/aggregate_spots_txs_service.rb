class AggregateSpotsTxsService
  class << self
    def execute
      AggregateTransaction.transaction do
        OriginTransaction.available.year_to_date.where(trade_type: 'buy').order(event_time: :asc).group_by(&:original_symbol).each do |original_symbol, origin_txs|
          total_cost = 0
          total_qty = 0
          total_fee = 0
  
          origin_txs.each do |tx|
            total_cost += tx.amount
            total_qty += tx.qty
            total_fee += tx.fee
          end
  
          origin_tx = origin_txs.last
          aggregate_tx = AggregateTransaction.where(original_symbol: original_symbol, from_symbol: origin_tx.from_symbol, to_symbol: origin_tx.to_symbol,
                                                    fee_symbol: origin_tx.fee_symbol).first_or_create
  
          price = total_qty.zero? ? 0 : total_cost / total_qty
          revenue = origin_tx.current_price * total_qty - total_cost
          roi = revenue / total_cost.abs
  
          aggregate_tx.update(price: price, qty: total_qty, amount: total_cost, fee: total_fee, last_trade_at: origin_tx.event_time,
                            current_price: origin_tx.current_price, revenue: revenue, roi: roi)
        end

        get_percent_changes
      end
    end

    def get_percent_changes
      result = CoinService.get_percent_changes(AggregateTransaction.pluck(:from_symbol))
      result.each do |r|
        AggregateTransaction.where(from_symbol: r[0].upcase).update_all(percentage_24h: r[1], percentage_7d: r[2])
      end
    end
  end
end
