class User < ApplicationRecord
  # Deviseで有効にしているモジュール一覧
  devise :database_authenticatable, # メール+パスワードでのログイン機能
         :registerable,             # 新規ユーザー登録機能
         :recoverable,              # パスワードリセット機能
         :rememberable,             # ログイン状態を保持する機能
         :validatable               # メール形式・パスワードの自動バリデーション

  # Postモデルとの関連付け
  # 1人のUserは複数のPostを持つ（1対多の関係）
  # dependent: :destroy = ユーザー削除時に関連する投稿も自動削除
  # これによりデータの整合性を保つ
  has_many :posts, dependent: :destroy

  # Achievementモデルとの関連付け
  # 1人のUserは複数のAchievementを持つ（1対多の関係）
  # dependent: :destroy = ユーザー削除時に関連する達成記録も自動削除
  has_many :achievements, dependent: :destroy
end