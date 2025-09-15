Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check
  
  # ルートページをホームページに変更
  root "home#index"
  
  # 投稿一覧への直接アクセス用
  get :posts_index, to: "posts#index"
  
  get :mypage, to: "users#show"
  
  resources :posts do
    resources :achievements, only: [:create]
  end
end