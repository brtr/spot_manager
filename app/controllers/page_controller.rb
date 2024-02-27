class PageController < ApplicationController
  def health_check
    render plain: "ok"
  end

  def open_spot_orders
    @page_index = 4
    @symbol = params[:search]
    @trade_type = params[:trade_type]
    @source = params[:source]
    open_orders = OpenSpotOrder.where.not(from_symbol: ['BTC', 'ETH']).order(order_time: :desc)
    @total_summary = open_orders.total_summary
    @symbols = open_orders.pluck(:from_symbol).uniq
    @sources = open_orders.pluck(:source).uniq
    open_orders = open_orders.where(from_symbol: @symbol) if @symbol.present?
    open_orders = open_orders.where(trade_type: @trade_type) if @trade_type.present?
    open_orders = open_orders.where(source: @source) if @source.present?
    @open_orders = open_orders.page(params[:page]).per(15)
  end
end
