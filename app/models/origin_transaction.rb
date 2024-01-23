class OriginTransaction < ApplicationRecord
  SKIP_SYMBOLS = %w(BTC ETH).freeze
  FILTER_SYMBOL = %w(USDC).freeze

  def self.available
    OriginTransaction.where('from_symbol NOT IN (?) and ((from_symbol IN (?) AND amount >= 50) OR from_symbol NOT IN (?))', FILTER_SYMBOL, SKIP_SYMBOLS, SKIP_SYMBOLS)
  end

  def self.year_to_date
    OriginTransaction.where('event_time >= ? and trade_type = ?', DateTime.parse('2023-01-01'), 'buy')
  end

  def self.total_summary
    records = OriginTransaction.available.year_to_date
    profit_records = records.select{|r| r.revenue > 0}
    loss_records = records.select{|r| r.revenue < 0}
    total_cost = calculate_field(records, :amount)
    total_estimated_revenue = records.where(trade_type: 'buy').sum(&:revenue)
    total_roi = total_cost.zero? ? 0 : total_estimated_revenue / total_cost
    date = Date.yesterday
    infos = TransactionsSnapshotInfo.where("event_date <= ?", date)

    {
      profit_count: profit_records.count,
      profit_amount: calculate_field(profit_records),
      loss_count: loss_records.count,
      loss_amount: calculate_field(loss_records),
      total_cost: total_cost,
      total_revenue: records.where(trade_type: 'sell').sum(&:revenue),
      total_estimated_revenue: total_estimated_revenue,
      total_roi: total_roi,
      # max_profit: infos.max_profit,
      # max_profit_date: $redis.get("#{date.to_s}_spots_max_profit_date"),
      # max_loss: infos.max_loss,
      # max_loss_date: $redis.get("#{date.to_s}_spots_max_loss_date"),
      # max_revenue: infos.max_revenue,
      # max_revenue_date: $redis.get("#{date.to_s}_spots_max_revenue_date"),
      # min_revenue: infos.min_revenue,
      # min_revenue_date: $redis.get("#{date.to_s}_spots_min_revenue_date"),
      # max_roi: infos.max_roi,
      # max_roi_date: $redis.get("#{date.to_s}_spots_max_roi_date"),
      # min_roi: infos.min_roi,
      # min_roi_date: $redis.get("#{date.to_s}_spots_min_roi_date"),
      # max_profit_roi: infos.max_profit_roi,
      # max_profit_roi_date: $redis.get("#{date.to_s}_spots_max_profit_roi_date"),
      # max_loss_roi: infos.max_loss_roi,
      # max_loss_roi_date: $redis.get("#{date.to_s}_spots_max_loss_roi_date")
    }
  end

  def revenue_ratio(total_revenue)
    ratio = (revenue / total_revenue).abs
    revenue > 0 ? ratio : ratio * -1
  end

  def cost_ratio(total_cost)
    amount / total_cost
  end

  def get_current_price_by_source
    OriginTransaction.get_current_price_by_source(original_symbol, from_symbol, source)
  end

  def self.get_current_price_by_source(original_symbol, from_symbol, source)
    price = $redis.get("spot_price_#{from_symbol}_current").to_f
    if price == 0
      price = case source
      when "binance"
        BinanceSpotsService.new.get_price(original_symbol)[:price].to_f rescue 0
      when "bitget"
        BitgetSpotsService.new.get_price(original_symbol)['data'].first["lastPr"].to_f rescue 0
      when "gate"
        GateSpotsService.new.get_price(original_symbol).first["last"].to_f rescue 0
      when "okx"
        OkxSpotsService.new.get_price(original_symbol)["data"].first["last"].to_f rescue 0
      end
      price = OriginTransaction.get_coin_price(from_symbol, Date.yesterday) if price.zero?
      $redis.set("spot_price_#{from_symbol}_current", price, ex: 2.hours)
    end
    price
  end

  def self.update_current_price(original_symbol, source)
    txs = OriginTransaction.where(original_symbol: original_symbol, source: source)
    return if txs.blank?
    price = get_current_price_by_source(original_symbol, txs.first.from_symbol, source)
    txs.update_all(current_price: price) if price != 0
  end

  private
  def self.calculate_field(records, field_name = :revenue)
    buys, sells = records.partition { |record| record.trade_type == "buy" }
    buys.sum { |record| record.send(field_name) } - sells.sum { |record| record.send(field_name) }
  end
end
