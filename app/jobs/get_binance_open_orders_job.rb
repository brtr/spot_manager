class GetBinanceOpenOrdersJob < ApplicationJob
  SOURCE = 'binance'
  queue_as :daily_job

  def perform
    get_spot_orders
  end

  def get_spot_orders
    open_orders = BinanceSpotsService.new.get_open_orders

    OpenSpotOrder.transaction do
      open_orders.each do |open_order|
        price = open_order[:price].to_f
        qty = open_order[:origQty].to_f
        amount = price * qty
        symbol = open_order[:symbol]
        from_symbol = symbol.split('USDT')[0]
        current_price = get_current_price(symbol, from_symbol)
        order = OpenSpotOrder.where(order_id: open_order[:orderId], symbol: symbol, source: SOURCE).first_or_initialize
        order.update(
          status: open_order[:status],
          price: price,
          current_price: current_price,
          orig_qty: qty,
          executed_qty: open_order[:executedQty],
          amount: amount,
          order_type: open_order[:type],
          trade_type: open_order[:side]&.downcase,
          stop_price: open_order[:stopPrice],
          order_time: Time.at(open_order[:time]/1000)
        )
      end

      symbols = open_orders.map{|order| order[:symbol]}.uniq
      OpenSpotOrder.where(source: SOURCE).where.not(symbol: symbols).delete_all
    end
  end

  def get_current_price(symbol, from_symbol)
    price = $redis.get("binance_spot_price_#{symbol}").to_f
    if price == 0
      price = BinanceSpotsService.new.get_price(symbol)[:price].to_f rescue 0
      price = CoinService.get_price_by_date(from_symbol) if price.zero?
      $redis.set("binance_spot_price_#{symbol}", price, ex: 2.hours)
    end
    price
  end
end