require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # 開発環境でメールをブラウザで確認できるようにする
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Sidekiq::Web, at: "/sidekiq"  # Sidekiq Web UI
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"

  get :home, to: "home#index"

  get :mypage, to: "users#show"
  get :edit_profile, to: "users#edit"
  patch :update_profile, to: "users#update"

  resources :posts do
    get :autocomplete, on: :collection
    resources :achievements, only: [ :create, :destroy ]
    resources :comments, only: [ :create, :destroy ]
    resources :likes, only: [ :create, :destroy ]
  end

  get :terms, to: "pages#terms"
  get :privacy, to: "pages#privacy"
  get :usage, to: "pages#usage"
end
