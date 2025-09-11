class User < ApplicationRecord
  # Deviseで有効にしているモジュール一覧
  devise :database_authenticatable, # メール+パスワードでのログイン機能
         :registerable,             # 新規ユーザー登録機能
         :recoverable,              # パスワードリセット機能
         :rememberable,             # ログイン状態を保持する機能
         :validatable               # メール形式・パスワードの自動バリデーション
end
