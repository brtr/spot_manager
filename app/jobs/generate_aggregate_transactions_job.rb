class GenerateAggregateTransactionsJob < ApplicationJob
  queue_as :daily_job

  def perform
    AggregateSpotsTxsService.execute

    ForceGcJob.perform_later
  end
end
