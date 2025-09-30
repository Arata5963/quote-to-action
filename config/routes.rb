Rails.application.routes.draw do
  devise_for :users

  # 開発環境でメールをブラウザで確認できるようにする
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"

  get :home, to: "home#index"

  get :mypage, to: "users#show"
  get :edit_profile, to: "users#edit"
  patch :update_profile, to: "users#update"

  resources :user_badges, only: [ :index ], path: "badges"

  resources :posts do
    resources :achievements, only: [ :create, :destroy ]
  end
end
