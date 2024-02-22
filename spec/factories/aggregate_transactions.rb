FactoryBot.define do
  factory :aggregate_transaction do
    original_symbol { "EOSUSDT" }
    from_symbol { "EOS" }
    fee_symbol { "USDT" }
    price { 1 }
    qty { 2 }
    amount { 2 }
    current_price { 1.5 }
    revenue { 1 }
    roi { 0.5 }
  end
end
