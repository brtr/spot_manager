class GetOkxOpenOrdersJob < ApplicationJob
  SOURCE = 'okx'
  queue_as :daily_job

  def perform
    get_spot_orders
  end

  def get_spot_orders
    open_orders = OkxSpotsService.new.get_open_orders['data']

    OpenSpotOrder.transaction do
      open_orders.each do |open_order|
        price = open_order['px'].to_f
        qty = open_order['sz'].to_f
        amount = price * qty
        symbol = open_order['instId']
        from_symbol = symbol.split('-USDT')[0]
        current_price = get_current_price(symbol, from_symbol)
        order = OpenSpotOrder.where(order_id: open_order['ordId'], symbol: symbol, source: SOURCE).first_or_initialize
        order.update(
          status: open_order['state'],
          price: price,
          current_price: current_price,
          orig_qty: qty,
          executed_qty: open_order['accFillSz'],
          amount: amount,
          order_type: open_order['ordType'],
          trade_type: open_order['side'],
          stop_price: open_order['tpTriggerPx'],
          order_time: Time.at(open_order['cTime'].to_i / 1000)
        )
      end

      symbols = open_orders.map{|order| order['instId']}.uniq
      OpenSpotOrder.where(source: SOURCE).where.not(symbol: symbols).delete_all
    end
  end

  def get_current_price(symbol, from_symbol)
    price = $redis.get("okx_spot_price_#{symbol}").to_f
    if price == 0
      price = OkxSpotsService.new.get_price(symbol)["data"].first["last"].to_f rescue 0
      price = get_coin_price(from_symbol) if price.zero?
      $redis.set("okx_spot_price_#{symbol}", price, ex: 2.hours)
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
end