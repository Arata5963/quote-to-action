Rails.application.routes.draw do
  # Devise認証ルーティング（ユーザー登録・ログイン・ログアウト）
  devise_for :users

  # 本番環境で「Railsアプリが正常に動いているか」を確認するための軽量な監視用ルート。
  get "up" => "rails/health#show", as: :rails_health_check

  # ルートページを投稿一覧に設定
  # ログインユーザーが最初に見るページ（アプリのメイン機能）
  root "posts#index"

  # Posts機能のRESTfulルーティング
  # GET    /posts          posts#index   (投稿一覧)
  # GET    /posts/new      posts#new     (新規投稿フォーム)
  # POST   /posts          posts#create  (投稿作成処理)
  # GET    /posts/:id      posts#show    (投稿詳細)
  # GET    /posts/:id/edit posts#edit    (投稿編集フォーム)
  # PATCH  /posts/:id      posts#update  (投稿更新処理)
  # DELETE /posts/:id      posts#destroy (投稿削除処理)
  resources :posts

  # Photos機能（実験用・今後削除予定）
  # MVPには含まれないため、必要に応じて削除
  resources :photos, only: [ :index, :new, :create, :show, :edit, :update ]
end
