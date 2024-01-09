module ApplicationHelper
  def transactions_table_headers
    [
      {
        name: "交易时间",
        sort: "event_time"
      },
      {
        name: "交易对",
        sort: "from_symbol"
      },
      {
        name: "类别",
        sort: "none"
      },
      {
        name: "成交价",
        sort: "price"
      },
      {
        name: "成本价",
        sort: "cost"
      },
      {
        name: "当前价",
        sort: "none"
      },
      {
        name: "数量",
        sort: "none"
      },
      {
        name: "交易金额",
        sort: "amount"
      },
      {
        name: "币种投入/总投入",
        sort: "cost_ratio"
      },
      {
        name: "预计收益 / 实际收益",
        sort: "revenue"
      },
      {
        name: "预计ROI / 实际ROI",
        sort: "roi"
      },
      {
        name: "收益/总收益",
        sort: "revenue_ratio"
      },
      {
        name: "来源",
        sort: "none"
      }
    ]
  end

  def change_sort_type(sort)
    sort == 'asc' ? "desc" : "asc"
  end

  def ch_remote_params(params,sort)
    {
      sort: sort,
      sort_type: "#{change_sort_type(params[:sort_type])}",
      search: params[:search],
    }
  end

  def trade_type_style(trade_type)
    trade_type.to_s.downcase == 'sell' ? "text-danger" : "text-success"
  end

  def price_change_style(data)
    c = data.to_f < 0 ? "text-danger" : "text-success"
    "<span class='#{c}'>#{data}</span>".html_safe
  end

  def get_date_format(date)
    date.strftime('%Y-%m-%d') rescue ''
  end

  def get_datetime_format(datetime)
    datetime.strftime('%Y-%m-%d %H:%M') rescue ''
  end

  def display_spot_tx_revenue(revenue, to_symbol, trade_type)
    str = "#{revenue.round(4)} #{to_symbol}"
    str += "(预计)" if trade_type == 'buy'
    str
  end

  def display_spot_tx_roi(roi, trade_type)
    str = "#{(roi * 100).round(4)}%"
    str += "(预计)" if trade_type == 'buy'
    str
  end
end
