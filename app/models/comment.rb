class Comment < ApplicationRecord
  # ====================
  # アソシエーション(関連付け)
  # ====================
  # コメントは1人のユーザーに属する
  belongs_to :user

  # コメントは1つの投稿に属する
  belongs_to :post

  # ====================
  # 通知設定
  # ====================
  # コメント時に投稿者に通知を送る（自分の投稿には通知しない）
  acts_as_notifiable :users,
    targets: ->(comment, _key) { [ comment.post.user ] unless comment.user == comment.post.user },
    group: :post,
    notifier: :user,
    email_allowed: false,
    notifiable_path: :post_path_for_notification

  # ====================
  # コールバック
  # ====================
  after_create :send_notification

  # ====================
  # バリデーション(入力値検証)
  # ====================
  # コメント本文は必須
  validates :content, presence: true

  # ★★★ string型なので文字数制限を調整 ★★★
  # string型はデータベースレベルで255文字制限があるため、
  # Railsレベルでも同様の制限を設定
  # minimum: 1 = 最低1文字以上必要(空白のみのコメント防止)
  # maximum: 255 = string型の上限に合わせる
  validates :content, length: { minimum: 1, maximum: 255 }

  # ====================
  # スコープ(よく使うクエリを定義)
  # ====================
  # コメントを新しい順に並べる
  # 投稿詳細ページで最新コメントを上に表示するため
  scope :recent, -> { order(created_at: :desc) }

  # コメントを古い順に並べる
  # チャット風の表示をしたい場合に使用
  scope :oldest_first, -> { order(created_at: :asc) }

  private

  def post_path_for_notification
    Rails.application.routes.url_helpers.post_path(post)
  end

  def send_notification
    notify :users if user != post.user
  end
end
