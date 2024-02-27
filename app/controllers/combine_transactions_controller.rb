class CombineTransactionsController < ApplicationController
  def index
    @page_index = 5
    sort = params[:sort].presence || "last_trade_at"
    sort_type = params[:sort_type].presence || "desc"
    @symbol = params[:search]
    @from_date = Date.parse(params[:from_date]) rescue nil
    @to_date = Date.parse(params[:to_date]) rescue nil
    txs = CombineTransaction.where('qty != ?', 0).order("#{sort} #{sort_type}")
    txs = txs.where('last_trade_at >= ?', @from_date) if @from_date.present?
    txs = txs.where('last_trade_at <= ?', @to_date) if @to_date.present?
    txs = txs.where(source: params[:source]) if params[:source].present?
    txs = txs.where(from_symbol: @symbol) if @symbol.present?
    @txs = txs.page(params[:page]).per(20)
    @total_summary = txs.total_summary
  end
end
