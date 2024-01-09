class GetSpotTradesJob < ApplicationJob
  queue_as :daily_job
  TRADE_SYMBOL = 'USDT'.freeze
  SOURCE = 'binance'.freeze
  SKIP_SYMBOLS = ['BUSD'].freeze

  def perform(symbol)
    return if symbol.in?(SKIP_SYMBOLS)
    origin_symbol = "#{symbol}#{TRADE_SYMBOL}"
    txs = OriginTransaction.where(source: SOURCE, original_symbol: origin_symbol)
    trades = BinanceSpotsService.new.get_my_trades(origin_symbol)
    current_price = get_current_price(origin_symbol, symbol)
    if trades.is_a?(String) || trades.blank?
      Rails.logger.debug "获取不到#{origin_symbol}的交易记录"
      txs.each{|tx| update_tx(tx, current_price)} if txs.any?
      combine_trades(origin_symbol, current_price)
      return false
    end

    ids = []
    OriginTransaction.transaction do
      trades.each do |trade|
        trade_type = trade[:isBuyer] ? 'buy' : 'sell'
        tx = OriginTransaction.where(source: SOURCE, order_id: trade[:id], event_time: Time.at(trade[:time] / 1000))
                              .first_or_create(original_symbol: trade[:symbol], from_symbol: symbol, to_symbol: TRADE_SYMBOL, fee_symbol: trade[:commissionAsset],
                                               price: trade[:price], qty: trade[:qty], amount: trade[:quoteQty], fee: trade[:commission], trade_type: trade_type)
        update_tx(tx, current_price)
        ids.push(tx.id)
      end

      txs.where.not(id: ids).each do |tx|
        update_tx(tx, current_price)
      end

      combine_trades(origin_symbol, current_price)
    end

    $redis.del("origin_transactions_total_summary")
  end

  def get_current_price(symbol, from_symbol)
    price = $redis.get("binance_spot_price_#{symbol}").to_f
    if price == 0
      price = BinanceSpotsService.new.get_price(symbol)[:price].to_f rescue 0
      price = get_coin_price(from_symbol) if price.zero?
      $redis.set("binance_spot_price_#{symbol}", price, ex: 2.hours)
    end

    price.to_f
  end

  def get_coin_price(symbol)
    date = Date.yesterday
    url = ENV['COIN_ELITE_URL'] + "/api/coins/history_price?symbol=#{symbol}&from_date=#{date}&to_date=#{date}"
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    data['result'].values[0].to_f rescue nil
  end

  def update_tx(tx, current_price)
    tx.current_price = current_price
    if tx.cost.to_f.zero?
      tx.cost = get_spot_cost(tx_id: tx.id) || tx.price
    end
    tx.revenue = get_revenue(tx.trade_type, tx.amount, tx.cost, tx.qty, current_price)
    tx.roi = tx.revenue / tx.amount
    tx.save
  end

  def combine_trades(symbol, current_price)
    CombineTransaction.transaction do
      total_cost = 0
      total_qty = 0
      total_fee = 0
      total_sold_revenue = 0

      origin_txs = OriginTransaction.available.year_to_date.where(source: SOURCE, original_symbol: symbol).order(event_time: :asc)
      return if origin_txs.empty?
      origin_txs.each do |tx|
        if tx.trade_type == 'buy'
          total_cost += tx.amount
          total_qty += tx.qty
        else
          total_cost -= tx.amount
          total_qty -= tx.qty
          total_sold_revenue += tx.revenue
        end

        total_fee += tx.fee
      end

      origin_tx = origin_txs.first
      combine_tx = CombineTransaction.where(source: SOURCE, original_symbol: symbol, from_symbol: origin_tx.from_symbol, to_symbol: origin_tx.to_symbol, fee_symbol: origin_tx.fee_symbol, trade_type: 'buy').first_or_create

      price = total_qty.zero? ? 0 : total_cost / total_qty
      revenue = current_price * total_qty - total_cost
      roi = revenue / total_cost.abs

      combine_tx.update(price: price, qty: total_qty, amount: total_cost, fee: total_fee, current_price: current_price, revenue: revenue, roi: roi, sold_revenue: total_sold_revenue)
    end
  end

  def get_revenue(trade_type, amount, cost, qty, current_price)
    if trade_type == 'sell'
      amount - cost * qty
    else
      current_price * qty - amount
    end
  end

  def get_spot_cost(tx_id: nil, symbol: nil, amount: nil, qty: nil)
    txs = OriginTransaction.available.year_to_date.where(source: SOURCE, original_symbol: original_symbol)

    if tx_id.present? && OriginTransaction.exists?(id: tx_id)
      txs = txs.where('id < ?', tx_id)
    end

    return if txs.blank?

    total_cost = txs.sum(&:amount)
    total_qty = txs.sum(&:qty)
    total_cost / total_qty
  end
end
