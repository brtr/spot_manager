class OpenSpotOrder < ApplicationRecord
  def margin_rate
    current_price.to_f.zero? ? 0 : ((current_price - price) / current_price) * 100
  end

  def self.total_summary
    records = OpenSpotOrder.all
    total_cost = records.sum(&:amount)
    total_qty = records.sum(&:orig_qty)

    {
      total_cost: total_cost,
      total_qty: total_qty
    }
  end
end
