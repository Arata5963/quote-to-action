class Post < ApplicationRecord
  # ユーザーとの関連付け（1つのPostは1人のUserに属する）
  # Railsが自動的にuser_idを使ってUserモデルと関連付け
  belongs_to :user
  
  # 達成記録との関連付け（1つのPostは複数のAchievementを持つ）
  # 投稿が削除されたら、関連する達成記録も全て削除
  has_many :achievements, dependent: :destroy

  # i18n（国際化）を活用したバリデーション設定
  # エラーメッセージは config/locales/ja.yml で管理
  # presenceとlengthのエラーメッセージが自動的に日本語化される
  validates :trigger_content,
            presence: true,
            length: { minimum: 10, maximum: 1000 }

  validates :action_plan,
            presence: true,
            length: { minimum: 10, maximum: 500 }

  # スコープ定義：よく使う検索条件をメソッドとして定義
  # コントローラーで @posts = current_user.posts.recent のように使用
  scope :recent, -> { order(created_at: :desc) }

  # 特定ユーザーの投稿取得用（認可制御で使用）
  scope :by_user, ->(user) { where(user: user) }
end