class OriginTransactionsController < ApplicationController
  def index
    @page_index = 1
    sort = params[:sort].presence || "event_time"
    sort_type = params[:sort_type].presence || "desc"
    txs = OriginTransaction.available.year_to_date.order("#{sort} #{sort_type}")
    @total_txs = txs
    txs = filter_txs(txs)
    @from_date = Date.parse(params[:from_date]) rescue nil
    @to_date = Date.parse(params[:to_date]) rescue nil
    txs = txs.where('event_time >= ?', @from_date) if @from_date.present?
    txs = txs.where('event_time <= ?', @to_date) if @to_date.present?
    @txs = txs.page(params[:page]).per(20)
    @total_summary = txs.total_summary
  end

  def edit
    @tx = OriginTransaction.find params[:id]
  end

  def update
    @tx = OriginTransaction.find_by_id params[:id]
    @tx.update(tx_params)
  end

  def bulk_edit
  end

  def bulk_update
    @txs = OriginTransaction.where(id: params[:ids].split(','))
    @txs.update_all(campaign: params[:campaign])

    redirect_to origin_transactions_path, notice: "批量更新campaign成功"
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

  def import_csv
    if params[:files].blank?
      flash[:alert] = "请选择文件"
      redirect_to root_path
    else
      source = params[:file_source].presence || 'binance'
      import_status = ImportBinanceCsvService.new(params[:files].first, source).call

      if import_status[:status].to_i == 1
        flash[:notice] = import_status[:message]
      else
        flash[:alert] = import_status[:message]
      end

      redirect_to root_path
    end
  end

  def filter_by_campaign
    @page_index = 9
    @campaign = params[:campaign]
    txs = OriginTransaction.available.year_to_date.order(event_time: :desc)
    @total_txs = txs

    if @campaign.present?
      txs = txs.where(campaign: @campaign)
      @txs = txs.page(params[:page]).per(20)
      @total_summary = txs.total_summary
    else
      @result = CampaignFilterService.execute(txs)
    end
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

    txs = txs.where(campaign: @campaign) if @campaign.present?
    txs = txs.where(source: @source) if @source.present?
    txs = txs.where(from_symbol: @symbol) if @symbol.present?
    txs
  end
end
