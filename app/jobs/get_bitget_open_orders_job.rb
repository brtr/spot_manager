class GetBitgetOpenOrdersJob < ApplicationJob
  SOURCE = 'bitget'
  queue_as :daily_job

  def perform
    open_orders = BitgetSpotsService.new.get_open_orders['data']

    OpenSpotOrder.transaction do
      open_orders.each do |open_order|
        price = open_order['priceAvg'].to_f
        qty = open_order['size'].to_f
        amount = price * qty
        symbol = open_order['symbol']
        from_symbol = symbol.split('USDT')[0]
        current_price = get_current_price(symbol, from_symbol)
        order = OpenSpotOrder.where(order_id: open_order['orderId'], symbol: symbol, source: SOURCE).first_or_initialize
        order.update(
          from_symbol: from_symbol,
          status: open_order['status'],
          price: price,
          current_price: current_price,
          orig_qty: qty,
          executed_qty: open_order['baseVolume'],
          amount: amount,
          order_type: open_order['orderType'],
          trade_type: open_order['side'],
          order_time: Time.at(open_order['uTime'].to_i / 1000)
        )
      end

      symbols = open_orders.map{|order| order['symbol']}.uniq
      OpenSpotOrder.where(source: SOURCE).where.not(symbol: symbols).delete_all
    end
  end

  def get_current_price(symbol, from_symbol)
    price = $redis.get("bitget_spot_price_#{symbol}").to_f
    if price == 0
      price = BitgetSpotsService.new.get_price(symbol)['data'].first["lastPr"].to_f rescue 0
      price = CoinService.get_price_by_date(from_symbol) if price.zero?
      $redis.set("bitget_spot_price_#{symbol}", price, ex: 2.hours)
    end

    price.to_f
  end
end