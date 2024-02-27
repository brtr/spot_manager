require "sidekiq/web"
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  root 'origin_transactions#index'
  mount Sidekiq::Web => "/sidekiq"

  resources :origin_transactions, only: [:index, :edit, :update] do
    collection do
      get :refresh
      get :revenue_chart
      post :import_csv
      get :filter_by_campaign
    end
  end

  resources :combine_transactions, only: :index
  resources :transactions_snapshot_infos, only: [:index, :show]
  resources :combine_tx_snapshot_infos, only: [:index, :show]
  resources :aggregate_transactions, only: :index
  resources :aggregate_tx_snapshot_infos, only: [:index, :show]

  get "/open_spot_orders" => "page#open_spot_orders", as: :open_spot_orders
  get "/healthcheck", to: "page#health_check"
end
