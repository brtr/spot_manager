class AggregateSpotsTxsService
  SYMBOLS = %w(AXL).freeze

  class << self
    def execute
      AggregateTransaction.transaction do
        OriginTransaction.available.year_to_date.where(trade_type: 'buy').order(event_time: :asc).group_by(&:from_symbol).each do |from_symbol, origin_txs|
          if from_symbol.in?(SYMBOLS)
            origin_txs.group_by(&:source).each do |source, txs|
              name = "#{from_symbol} / USDT(#{source})"
              update_tx(txs, from_symbol, name)
            end
          else
            update_tx(origin_txs, from_symbol)
          end
        end

        get_percent_changes
      end
    end

    def update_tx(origin_txs, from_symbol, name = nil)
      name ||= "#{from_symbol} / USDT"
      total_cost = 0
      total_qty = 0

      origin_txs.each do |tx|
        total_cost += tx.amount
        total_qty += tx.qty
      end

      origin_tx = origin_txs.last
      to_symbol = origin_tx.to_symbol
      aggregate_tx = AggregateTransaction.where(original_symbol: name, from_symbol: from_symbol, to_symbol: to_symbol).first_or_create

      price = total_qty.zero? ? 0 : total_cost / total_qty
      revenue = origin_tx.current_price * total_qty - total_cost
      roi = revenue / total_cost.abs

      aggregate_tx.update(price: price, qty: total_qty, amount: total_cost, last_trade_at: origin_tx.event_time,
                        current_price: origin_tx.current_price, revenue: revenue, roi: roi)
    end

    def get_percent_changes
      result = CoinService.get_percent_changes(AggregateTransaction.pluck(:from_symbol))
      result.each do |r|
        AggregateTransaction.where(from_symbol: r[0].upcase).update_all(percentage_24h: r[1], percentage_7d: r[2])
      end
    end
  end
end
