class GetOkxSpotTradesJob < ApplicationJob
  queue_as :daily_job
  SOURCE = 'okx'.freeze
  FEE_SYMBOL = 'USDT'.freeze

  def perform
    result = OkxSpotsService.new.get_orders rescue nil
    return if result.nil? || result['data'].nil?

    txs = OriginTransaction.where(source: SOURCE)
    ids = []

    OriginTransaction.transaction do
      result['data'].each do |d|
        next if d['category'] != 'normal'
        next if OriginTransaction.exists?(order_id: d['ordId'], source: 'okx')
        original_symbol = d['instId']
        qty = d['accFillSz'].to_f
        price = d['avgPx'].to_f
        amount = qty * price
        revenue = d['pnl'].to_f
        trade_type = d['side'].downcase
        from_symbol = original_symbol.split("-#{FEE_SYMBOL}")[0]
        event_time = Time.at(d['cTime'].to_i / 1000)
        cost = get_spot_cost(symbol: original_symbol, amount: amount, qty: qty) || price
        current_price = get_current_price(original_symbol, from_symbol)
        revenue = get_revenue(trade_type, amount, cost, qty, current_price) if revenue.to_f == 0
        roi = revenue / amount
        tx = OriginTransaction.where(order_id: d['ordId'], source: SOURCE).first_or_initialize
        tx.update(
          original_symbol: original_symbol,
          from_symbol: from_symbol,
          to_symbol: FEE_SYMBOL,
          fee_symbol: d['rebateCcy'],
          trade_type: trade_type,
          price: price,
          qty: qty,
          amount: amount,
          fee: d['fee'].to_f.abs,
          cost: cost,
          revenue: revenue,
          roi: roi,
          current_price: current_price,
          event_time: event_time
        )
        update_tx(tx)
        ids.push(tx.id)
      end

      txs.where.not(id: ids).each do |tx|
        update_tx(tx)
      end

      CombineSpotsTxsService.execute(SOURCE)
    end
  end

  def get_current_price(symbol, from_symbol)
    price = $redis.get("okx_spot_price_#{symbol}").to_f
    if price == 0
      price = OkxSpotsService.new.get_price(symbol)["data"].first["last"].to_f rescue 0
      price = CoinService.get_price_by_date(from_symbol) if price.zero?
      $redis.set("okx_spot_price_#{symbol}", price, ex: 2.hours)
    end

    price.to_f
  end

  def update_tx(tx)
    tx.current_price = get_current_price(tx.original_symbol, tx.from_symbol)
    if tx.cost.to_f.zero?
      tx.cost = get_spot_cost(tx_id: tx.id, symbol: tx.original_symbol) || tx.price
    end
    tx.revenue = get_revenue(tx.trade_type, tx.amount, tx.cost, tx.qty, tx.current_price)
    tx.roi = tx.revenue / tx.amount
    tx.save
  end

  def get_revenue(trade_type, amount, cost, qty, current_price)
    if trade_type == 'sell'
      amount - cost * qty
    else
      current_price * qty - amount
    end
  end

  def get_spot_cost(tx_id: nil, symbol: nil, amount: nil, qty: nil)
    txs = OriginTransaction.available.year_to_date.where(source: SOURCE, original_symbol: symbol)

    if tx_id.present? && OriginTransaction.exists?(id: tx_id)
      txs = txs.where('id < ?', tx_id)
    end

    return if txs.blank?

    total_cost = txs.sum(&:amount)
    total_qty = txs.sum(&:qty)
    total_cost / total_qty
  end
end
