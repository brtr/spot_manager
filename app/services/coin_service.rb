class CoinService
  class << self
    def get_volumes(symbol, date)
      url = ENV['COIN_ELITE_URL'] + "/api/coins/history_volume?symbol=#{symbol}&date=#{date}"
      response = RestClient.get(url)
      data = JSON.parse(response.body)
      data['result'].to_f rescue nil
    end
  end
end