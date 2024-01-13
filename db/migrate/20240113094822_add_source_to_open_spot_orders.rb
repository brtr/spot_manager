class AddSourceToOpenSpotOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :open_spot_orders, :source, :string, default: 'binance'
  end
end
