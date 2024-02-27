class GetGateOpenOrdersJob < ApplicationJob
  SOURCE = 'gate'
  queue_as :daily_job

  def perform
    open_orders = GateSpotsService.new.get_open_orders

    OpenSpotOrder.transaction do
      open_orders.each do |open_order|
        symbol = open_order['currency_pair']
        from_symbol = symbol.split('USDT')[0]
        open_order['orders'].each do |o|
          price = o['price'].to_f
          qty = o['amount'].to_f
          amount = price * qty
          current_price = get_current_price(symbol, from_symbol)
          order = OpenSpotOrder.where(order_id: o['id'], symbol: symbol, source: SOURCE).first_or_initialize
          order.update(
            from_symbol: from_symbol,
            status: o['status'],
            price: price,
            current_price: current_price,
            orig_qty: qty,
            executed_qty: qty - o['left'].to_f,
            amount: amount,
            order_type: o['type'],
            trade_type: o['side'],
            order_time: Time.at(o['update_time'].to_i)
          )
        end
      end

      symbols = open_orders.map{|order| order['currency_pair']}.uniq
      OpenSpotOrder.where(source: SOURCE).where.not(symbol: symbols).delete_all
    end
  end

  def get_current_price(symbol, from_symbol)
    price = $redis.get("gate_spot_price_#{symbol}").to_f
    if price == 0
      price = GateSpotsService.new.get_price(symbol).first["last"].to_f rescue 0
      price = CoinService.get_price_by_date(from_symbol) if price.zero?
      $redis.set("gate_spot_price_#{symbol}", price, ex: 2.hours)
    end

    price.to_f
  end
end