class GetSpotTransactionsJob < ApplicationJob
  queue_as :daily_job

  def perform
    data = BinanceSpotsService.new.get_account

    assets = data[:balances].select{|i| i[:free].to_f != 0 || i[:locked].to_f != 0}.map{|i| i[:asset]}

    assets.uniq.each do |asset|
      GetSpotTradesJob.perform_later(asset)
    end

    GetOkxSpotTradesJob.perform_later

    GetGateSpotTradesJob.perform_later

    GetBitgetSpotTradesJob.perform_later

    ForceGcJob.perform_later
    $redis.set("get_spot_transactions_refresh_time", Time.now)
  end
end
