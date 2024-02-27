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
          txs: origin_txs,
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

    def calculate_field(records, field_name = :revenue)
      buys, sells = records.partition { |record| record.trade_type == "buy" }
      buys.sum { |record| record.send(field_name) } - sells.sum { |record| record.send(field_name) }
    end
  end
end