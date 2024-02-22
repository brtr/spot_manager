FactoryBot.define do
  factory :open_spot_order do
    symbol { 'ENSUSDT' }
    price { 1 }
    orig_qty { 1 }
    amount { 1 }
  end
end
