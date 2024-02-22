FactoryBot.define do
  factory :aggregate_tx_snapshot_info do
    event_date { Date.yesterday }
  end
end
