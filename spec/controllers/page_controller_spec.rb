require "rails_helper"

RSpec.describe PageController, type: :controller do
  describe "GET open spot orders page" do
    before { create_list(:open_spot_orders, 10) }

    it "renders a successful response" do
      get :open_spot_orders

      expect(assigns(:open_orders).count).to eq(10)
      expect(response).to be_successful
      expect(response).to render_template(:open_spot_orders)
    end
  end
end