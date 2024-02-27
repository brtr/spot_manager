class AddFromSymbolToOpenSpotOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :open_spot_orders, :from_symbol, :string
  end
end
