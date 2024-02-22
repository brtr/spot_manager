require "rails_helper"

RSpec.describe AggregateTransactionsController, type: :controller do
  before do
    10.times{ create(:aggregate_transaction) }
  end

  describe "GET index" do
    it "renders a successful response" do
      get :index

      expect(assigns(:txs).count).to eq(10)
      expect(response).to be_successful
      expect(response).to render_template(:index)
    end
  end
end