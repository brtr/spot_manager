require 'openssl'
require 'rest-client'

class GateSpotsService
  BASE_URL = ENV['GATE_API_URL']

  def initialize
    @api_key = ENV["GATE_KEY"]
    @secret_key = ENV["GATE_SECRET"]
  end

  def get_trades(options='')
    begin
      request_path = '/api/v4/spot/my_trades'
      query_string = options
      do_request("get", request_path, query_string)
    rescue => e
      format_error_msg(e)
    end
  end

  def get_price(symbol)
    begin
      request_path = "/api/v4/spot/tickers?currency_pair=#{symbol}"
      url = BASE_URL + request_path
      response = RestClient.get(url)
      JSON.parse(response)
    rescue => e
      format_error_msg(e)
    end
  end

  private
  def do_request(method, request_path, query_string, payload_string = nil)
    url = BASE_URL + request_path + "?" + query_string
    timestamp = get_timestamp.to_s
    hashed_payload = Digest::SHA512.hexdigest(payload_string || "")
    sign = signed_data("#{method.upcase}\n#{request_path}\n#{query_string || ""}\n#{hashed_payload}\n#{timestamp}")
    headers = {
      "KEY" => @api_key,
      "SIGN" => sign,
      "Timestamp" => timestamp,
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }

    response = RestClient.get(url, headers)
    JSON.parse(response)
  end

  def signed_data(data)
    hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), @secret_key, data)
  end

  def get_timestamp
    Time.now.utc.to_f
  end

  def format_error_msg(e)
    "Error: #{e}"
  end
end