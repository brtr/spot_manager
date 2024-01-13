class CoinsView < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :coin_elite
  self.table_name = 'coins_view'

  has_many :histories, primary_key: :coin_id, foreign_key: :coin_id
  has_many :cmc_histories, primary_key: :coin_id, foreign_key: :coin_id
  belongs_to :coin

  scope :normal_caps, -> { where("market_cap_rank != ?", 0)}
  scope :search_name, ->(search) { where("name ilike ? OR symbol ilike ?", "%#{search}%", "%#{search}%") }
  scope :normal_market_cap, -> { where("market_cap_rank != ? and market_cap > ? and price > ?", 0, 0,0)}
  scope :without_stable, -> { where(is_stable: false) }

  def dynamic_price(date_picker)
    memo_price = memo["#{date_picker}"].to_d
    date_price = price.to_d - memo_price
    date_percent = memo_price == 0 ? 0 : (date_price / memo_price)

    {
      price: date_price,
      percent: date_percent
    }
  end

  def self.select_rank_coins(rank)
    case rank.to_i
    when 1 then where("market_cap_rank <= ?", 100)
    when 2 then where("market_cap_rank > ? and market_cap_rank <= ?", 100, 200)
    when 3 then where("market_cap_rank <= ?", 200)
    when 4 then where("market_cap_rank > ? and market_cap_rank <= ?", 200, 300)
    else
      where("market_cap_rank <= ?", 300)
    end
  end

  def self.rank_filter(filters)
    result = self
    filters.values.each do |filter|
      next unless filter["type"].present? && filter["condition"].present? && filter["value"].present?
      result = result.where("#{filter["type"]} #{filter["condition"]} ?", filter["value"])
    end
    result
  end
end