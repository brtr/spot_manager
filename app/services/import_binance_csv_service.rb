# frozen_string_literal: true

class ImportBinanceCsvService
  attr_reader :file, :source
  require "csv"

  def initialize(file, source)
    @file = file
    @source = source.downcase
    @total_count = 0
    @records = []
  end

  def call
    import_status = {
      status: 1,
      message: "Has unknow errors"
    }
    file_name = @file.original_filename

    if !is_valid_file?(file_name)
      import_status[:status] = -1
      import_status[:message] = "仅支持csv 和 xlxs 两种格式的文件"
    else
      options = {
        headers: true,
        encoding: 'utf-8'
      }
      begin
        if file_name.include?(".csv")
          tables = File.read(@file)
        else
          xlsx = Roo::Spreadsheet.open(@file)
          sheet = xlsx.sheet(0)
          tables = sheet.to_csv
        end
      rescue CSV::MalformedCSVError
        options[:encoding] = "windows-1251:utf-8"
        tables = File.read(@file, options)
      end

      csv_data = CSV.parse(tables, liberal_parsing: true, headers: true)
      fetch_transactions(csv_data)

      import_status[:message] = "正在同步合约交易记录，请稍后刷新页面"
    end
    import_status
  rescue => e
    import_status[:status] = -1
    import_status[:message] = e.message
    return import_status
  end

  private

  def fetch_transactions(csv_data)
    data = []
    csv_data.each do |row|
      symbol = row[1]
      event_time = DateTime.parse(row[0])
      if data.blank?
        data.push({symbol: symbol, event_time: event_time})
      else
        previous_d = data.select{|d| d[:symbol] == symbol}.last
        next if previous_d.present? && (event_time.to_i - previous_d[:event_time].to_i).abs < 5.days.to_i
        data.push({symbol: symbol, event_time: event_time})
      end
    end

    data.each do |d|
      from_symbol = d[:symbol].split('USDT')[0]
      GetSpotTradesJob.perform_later(from_symbol)
    end
  end

  def is_valid_file?(file_name)
    %w(csv xlsx).include?(file_name.to_s.split(".").last)
  end
end