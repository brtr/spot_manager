# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_12_04_085731) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "combine_transactions", force: :cascade do |t|
    t.string "source"
    t.string "original_symbol"
    t.string "from_symbol"
    t.string "to_symbol"
    t.string "trade_type"
    t.string "fee_symbol"
    t.decimal "price", default: "0.0", null: false
    t.decimal "qty", default: "0.0", null: false
    t.decimal "amount", default: "0.0", null: false
    t.decimal "fee", default: "0.0", null: false
    t.decimal "revenue", default: "0.0", null: false
    t.decimal "roi", default: "0.0", null: false
    t.decimal "current_price", default: "0.0", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "sold_revenue", default: "0.0"
    t.index ["original_symbol"], name: "index_combine_transactions_on_original_symbol"
    t.index ["source"], name: "index_combine_transactions_on_source"
  end

  create_table "combine_tx_snapshot_infos", force: :cascade do |t|
    t.date "event_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "combine_tx_snapshot_records", force: :cascade do |t|
    t.bigint "combine_tx_snapshot_info_id"
    t.string "source"
    t.string "original_symbol"
    t.string "from_symbol"
    t.string "to_symbol"
    t.string "trade_type"
    t.string "fee_symbol"
    t.decimal "price", default: "0.0", null: false
    t.decimal "qty", default: "0.0", null: false
    t.decimal "amount", default: "0.0", null: false
    t.decimal "fee", default: "0.0", null: false
    t.decimal "revenue", default: "0.0", null: false
    t.decimal "roi", default: "0.0", null: false
    t.decimal "current_price", default: "0.0", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "sold_revenue", default: "0.0"
    t.index ["combine_tx_snapshot_info_id"], name: "index_snapshot_info"
  end

  create_table "open_spot_orders", force: :cascade do |t|
    t.string "symbol"
    t.string "order_id"
    t.string "trade_type"
    t.string "status"
    t.string "order_type"
    t.decimal "price"
    t.decimal "stop_price"
    t.decimal "orig_qty"
    t.decimal "executed_qty"
    t.decimal "amount"
    t.datetime "order_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "current_price"
    t.index ["order_id"], name: "index_open_spot_orders_on_order_id"
    t.index ["order_time"], name: "index_open_spot_orders_on_order_time"
    t.index ["symbol"], name: "index_open_spot_orders_on_symbol"
    t.index ["trade_type"], name: "index_open_spot_orders_on_trade_type"
  end

  create_table "origin_transactions", force: :cascade do |t|
    t.string "order_id"
    t.string "source"
    t.string "original_symbol"
    t.string "from_symbol"
    t.string "to_symbol"
    t.string "fee_symbol"
    t.string "trade_type"
    t.string "campaign"
    t.decimal "price", default: "0.0", null: false
    t.decimal "qty", default: "0.0", null: false
    t.decimal "amount", default: "0.0", null: false
    t.decimal "fee", default: "0.0", null: false
    t.decimal "revenue", default: "0.0", null: false
    t.decimal "roi", default: "0.0", null: false
    t.decimal "current_price", default: "0.0", null: false
    t.datetime "event_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "cost", default: "0.0"
    t.index ["campaign"], name: "index_origin_transactions_on_campaign"
    t.index ["order_id"], name: "index_origin_transactions_on_order_id"
    t.index ["source"], name: "index_origin_transactions_on_source"
    t.index ["trade_type"], name: "index_origin_transactions_on_trade_type"
  end

  create_table "transactions_snapshot_infos", force: :cascade do |t|
    t.date "event_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "total_cost"
    t.decimal "total_revenue"
    t.decimal "total_roi"
    t.integer "profit_count"
    t.decimal "profit_amount"
    t.integer "loss_count"
    t.decimal "loss_amount"
    t.decimal "max_profit"
    t.decimal "max_loss"
    t.decimal "max_revenue"
    t.decimal "min_revenue"
    t.datetime "max_profit_date"
    t.datetime "max_loss_date"
    t.datetime "max_revenue_date"
    t.datetime "min_revenue_date"
    t.decimal "max_roi"
    t.datetime "max_roi_date"
    t.decimal "max_profit_roi"
    t.datetime "max_profit_roi_date"
    t.decimal "max_loss_roi"
    t.datetime "max_loss_roi_date"
    t.decimal "min_roi"
    t.datetime "min_roi_date"
    t.index ["event_date"], name: "index_transactions_snapshot_infos_on_event_date"
  end

  create_table "transactions_snapshot_records", force: :cascade do |t|
    t.integer "transactions_snapshot_info_id"
    t.string "order_id"
    t.string "source"
    t.string "original_symbol"
    t.string "from_symbol"
    t.string "to_symbol"
    t.string "fee_symbol"
    t.string "trade_type"
    t.string "campaign"
    t.decimal "price", default: "0.0", null: false
    t.decimal "qty", default: "0.0", null: false
    t.decimal "amount", default: "0.0", null: false
    t.decimal "fee", default: "0.0", null: false
    t.decimal "revenue", default: "0.0", null: false
    t.decimal "roi", default: "0.0", null: false
    t.decimal "current_price", default: "0.0", null: false
    t.datetime "event_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["amount"], name: "index_transactions_snapshot_records_on_amount"
    t.index ["event_time"], name: "index_transactions_snapshot_records_on_event_time"
    t.index ["from_symbol"], name: "index_transactions_snapshot_records_on_from_symbol"
    t.index ["revenue"], name: "index_transactions_snapshot_records_on_revenue"
    t.index ["trade_type"], name: "index_transactions_snapshot_records_on_trade_type"
    t.index ["transactions_snapshot_info_id"], name: "index_snapshot_info_id"
  end

end
