Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check
  
  # ルートページを投稿一覧に変更
  root "posts#index"
  
  # 投稿一覧への直接アクセス用
  get :posts_index, to: "posts#index"
  
  get :mypage, to: "users#show"
  get :edit_profile, to: "users#edit"
  patch :update_profile, to: "users#update"
  
  # バッジ一覧追加
  resources :user_badges, only: [:index], path: 'badges'
  
  resources :posts do
    resources :achievements, only: [:create, :destroy]
  end
end