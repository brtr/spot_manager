class OriginTransactionsController < ApplicationController
  def index
    @page_index = 1
    sort = params[:sort].presence || "event_time"
    sort_type = params[:sort_type].presence || "desc"
    txs = OriginTransaction.available.year_to_date.order("#{sort} #{sort_type}")
    @total_txs = txs
    txs = filter_txs(txs)
    @event_date = Date.parse(params[:event_date]) rescue nil
    txs = txs.where(event_time: @event_date.all_day) if @event_date.present?
    @txs = txs.page(params[:page]).per(20)
    @total_summary = txs.total_summary
  end

  def edit
    @tx = OriginTransaction.find params[:id]
  end

  def update
    @tx = OriginTransaction.find_by_id params[:id]
    if tx_params[:campaign].present?
      @tx.update(tx_params)
      flash[:notice] = "更新成功"
    else
      flash[:alert] = "campaign不能为空，请重新输入"
    end

    redirect_to origin_transactions_path
  end

  def refresh
    GetSpotTransactionsJob.perform_later

    redirect_to origin_transactions_path, notice: "正在更新，请稍等刷新查看最新价格以及其他信息..."
  end

  def revenue_chart
    @page_index = 3
    infos = TransactionsSnapshotInfo.where(event_date: [period_date..Date.yesterday]).order(event_date: :asc)
    @records = infos.map do |info|
      {info.event_date => info.total_revenue}
    end.inject(:merge)
  end

  private
  def tx_params
    params.require(:origin_transaction).permit(:campaign)
  end

  def period_date
    case params[:period]
    when "quarter" then Date.today.last_quarter.to_date
    else Date.today.last_month.to_date
    end
  end

  def filter_txs(txs)
    @symbol = params[:search]
    @campaign = params[:campaign]
    @source = params[:source]
    @trade_type = params[:trade_type]

    txs = txs.where(campaign: @campaign) if @campaign.present?
    txs = txs.where(source: @source) if @source.present?
    txs = txs.where(original_symbol: @symbol) if @symbol.present?
    txs = txs.where(trade_type: @trade_type) if @trade_type.present?
    txs
  end
end
