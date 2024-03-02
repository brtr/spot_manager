# frozen_string_literal: true

class CampaignFilterService
  class << self
    def execute(txs)
      result = {}
      txs.group_by(&:campaign).each do |campaign, origin_txs|
        next if campaign.blank?
        profit_records = origin_txs.select{|r| r.revenue > 0}
        loss_records = origin_txs.select{|r| r.revenue < 0}
        total_cost = calculate_field(origin_txs, :amount)
        total_estimated_revenue = origin_txs.select{|r| r.trade_type == 'buy'}.sum(&:revenue)
        total_roi = total_cost.zero? ? 0 : total_estimated_revenue / total_cost
        result[campaign] = {
          txs: aggregate_txs(origin_txs),
          profit_count: profit_records.count,
          profit_amount: calculate_field(profit_records),
          loss_count: loss_records.count,
          loss_amount: calculate_field(loss_records),
          total_cost: total_cost,
          total_revenue: origin_txs.select{|r| r.trade_type == 'sell'}.sum(&:revenue),
          total_estimated_revenue: total_estimated_revenue,
          total_roi: total_roi,
        }
      end

      result
    end

    def aggregate_txs(txs)
      data = []
      percent_changes = CoinService.get_percent_changes(txs.map(&:from_symbol).uniq)
      txs.select{|x| x.trade_type == 'buy'}.sort_by{|x| x.event_time}.group_by(&:from_symbol).each do |from_symbol, origin_txs|
        total_cost = 0
        total_qty = 0
        total_fee = 0

        origin_txs.each do |tx|
          total_cost += tx.amount
          total_qty += tx.qty
          total_fee += tx.fee
        end

        origin_tx = origin_txs.last
        to_symbol = origin_tx.to_symbol
        price = total_qty.zero? ? 0 : total_cost / total_qty
        current_price = origin_tx.current_price
        revenue = current_price * total_qty - total_cost
        roi = revenue / total_cost.abs
        margin_price = current_price - price
        rate = margin_price / price
        r = percent_changes.select{|pc| pc[0].upcase == from_symbol}.first || []

        data.push({
          symbol: "#{from_symbol}#{to_symbol}", cost: total_cost,
          price: price, qty: total_qty, amount: total_cost,
          current_price: current_price, revenue: revenue,
          percentage_24h: r[1], percentage_7d: r[2], margin_price: margin_price,
          rate: rate
        })
      end
      data
    end

    def calculate_field(records, field_name = :revenue)
      buys, sells = records.partition { |record| record.trade_type == "buy" }
      buys.sum { |record| record.send(field_name) } - sells.sum { |record| record.send(field_name) }
    end
  end
end