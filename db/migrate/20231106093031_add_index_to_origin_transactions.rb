class AddIndexToOriginTransactions < ActiveRecord::Migration[6.1]
  def change
    add_index :origin_transactions, :trade_type
  end
end
