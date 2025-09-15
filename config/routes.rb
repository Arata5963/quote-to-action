Rails.application.routes.draw do
  # Devise認証ルーティング（ユーザー登録・ログイン・ログアウト）
  devise_for :users
  # 本番環境で「Railsアプリが正常に動いているか」を確認するための軽量な監視用ルート。
  get "up" => "rails/health#show", as: :rails_health_check
  # ルートページを投稿一覧に設定
  # ログインユーザーが最初に見るページ（アプリのメイン機能）
  root "posts#index"
  
  # Posts機能のRESTfulルーティング + 達成機能のネスト
  resources :posts do
    # 達成機能：POST /posts/:post_id/achievements (達成記録作成)
    # 1つの投稿に対して達成記録を作成する
    resources :achievements, only: [:create]
  end
  
  # Photos機能（実験用・今後削除予定）
  # MVPには含まれないため、必要に応じて削除
  resources :photos, only: [ :index, :new, :create, :show, :edit, :update ]
end