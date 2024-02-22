require 'rails_helper'

RSpec.describe AggregateTransaction, type: :model do
  let(:aggregate_transaction) { create(:aggregate_transaction) }

  it "have a valid factory" do
    expect(aggregate_transaction).to be_valid
  end

  describe '#roi' do
    it 'should equal revenue divide amount' do
      expect(aggregate_transaction.roi).to eq (aggregate_transaction.revenue / aggregate_transaction.amount)
    end
  end

  describe '#cost_ratio' do
    it 'should equal amount divide total_cost' do
      total_cost = 100
      expect(aggregate_transaction.cost_ratio(total_cost)).to eq (aggregate_transaction.amount / total_cost)
    end
  end
end
