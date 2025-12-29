class Cheer < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :user
  belongs_to :post

  # ===== 通知設定 =====
  # 応援時に投稿者に通知を送る（自分の投稿には通知しない）
  acts_as_notifiable :users,
    targets: ->(cheer, _key) { [ cheer.post.user ] unless cheer.user == cheer.post.user },
    group: :post,
    notifier: :user,
    email_allowed: false,
    notifiable_path: :post_path_for_notification

  # ===== コールバック =====
  after_create :send_notification

  # ===== バリデーション =====
  # 同じユーザーが同じ投稿に重複して応援できないようにする
  validates :user_id, uniqueness: { scope: :post_id }

  private

  def post_path_for_notification
    Rails.application.routes.url_helpers.post_path(post)
  end

  def send_notification
    notify :users if user != post.user
  end
end
