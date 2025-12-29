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
  patch :mypage, to: "users#update"
  get "users/:id", to: "users#show", as: :user_profile

  get :bookshelf, to: "bookshelves#show"
  get "users/:id/bookshelf", to: "bookshelves#show", as: :user_bookshelf

  # 通知
  resources :notifications, only: [ :index ] do
    post :mark_as_read, on: :member
    post :mark_all_as_read, on: :collection
  end

  resources :posts do
    get :autocomplete, on: :collection
    resources :achievements, only: [ :create, :destroy ]
    resources :comments, only: [ :create, :destroy ]
    resources :cheers, only: [ :create, :destroy ]
    resource :recommendation, only: [ :show ]
  end

  get :terms, to: "pages#terms"
  get :privacy, to: "pages#privacy"
end
