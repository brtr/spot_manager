class CoinService
  class << self
    def get_volumes(symbol, date)
      url = ENV['COIN_ELITE_URL'] + "/api/coins/history_volume?symbol=#{symbol}&date=#{date}"
      response = RestClient.get(url)
      data = JSON.parse(response.body)
      data['result'].to_f rescue nil
    end

    def get_price_by_date(symbol, date: nil)
      date ||= Date.yesterday
      url = ENV['COIN_ELITE_URL'] + "/api/coins/history_price_by_symbol?symbol=#{symbol}&from_date=#{date}&to_date=#{date}"
      response = RestClient.get(url)
      data = JSON.parse(response.body)
      data['result'].values[0].to_f rescue nil
    end

    def get_price_range_by_dates(symbol, from_date: nil, to_date: nil)
      to_date ||= Date.yesterday
      from_date ||= to_date - 1.month
      url = ENV['COIN_ELITE_URL'] + "/api/coins/history_price_by_symbol?symbol=#{symbol}&from_date=#{from_date}&to_date=#{to_date}"
      response = RestClient.get(url)
      data = JSON.parse(response.body)
      data['result'] rescue nil
    end

    def get_price_range_by_dates_and_rank(from_date: nil, to_date: nil, from_rank: 1, to_rank: 100)
      to_date ||= Date.yesterday
      from_date ||= to_date - 1.month

      url = ENV['COIN_ELITE_URL'] + "/api/coins/history_prices?&from_date=#{from_date}&to_date=#{to_date}&from_rank=#{from_rank}&to_rank=#{to_rank}"
      response = RestClient.get(url)
      data = JSON.parse(response.body)
      data rescue nil
    end

    def sync_coin_history_price(symbol, from_date: nil, to_date: nil, platform: nil)
      to_date ||= Date.yesterday
      from_date ||= to_date - 1.year
      platform ||= 'cmc'
      url = ENV['COIN_ELITE_URL'] + '/api/coins/sync'
      payload = {
        symbol: symbol,
        start_date: from_date,
        end_date: to_date,
        platform: platform
      }
      response = RestClient.post(url, payload)
      data = JSON.parse(response.body)
      data rescue nil
    end

    def get_percent_changes(symbols)
      format_symbols = Base64.encode64(symbols.uniq.map(&:downcase).join(','))
      redis_key = "#{format_symbols}_percent_changes"
      result = $redis.get(redis_key)
      if result.nil?
        url = ENV['COIN_ELITE_URL'] + "/api/coins/percent_changes?symbols=#{format_symbols}"
        response = RestClient.get(url)
        data = JSON.parse(response.body)
        result = data['result'].to_json rescue nil
        $redis.set(redis_key, result, ex: 10.hours)
      end

      JSON.parse(result) rescue nil
    end
  end
end