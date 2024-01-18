class AddLastTradeAtToCombineTransactions < ActiveRecord::Migration[6.1]
  def change
    add_column :combine_transactions, :last_trade_at, :datetime
  end
end
