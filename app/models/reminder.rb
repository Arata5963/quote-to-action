class Reminder < ApplicationRecord
  belongs_to :user
  belongs_to :post

  before_validation :set_user_from_post

  validates :remind_time, presence: true
  validates :post_id, uniqueness: { scope: :user_id, message: "ごとに設定できるリマインダーは1つです" }
  validate :post_belongs_to_user

  # 指定時刻（HH:MM）に該当するリマインダーを取得
  scope :at_time, ->(time) { where(remind_time: time.beginning_of_minute..time.end_of_minute) }

  # 達成済みでない投稿のリマインダーのみ
  scope :active, -> { joins(:post).where(posts: { achieved_at: nil }) }

  # 送信対象（指定時刻かつアクティブ）
  scope :sendable_at, ->(time) { at_time(time).active }

  private

  def set_user_from_post
    self.user ||= post&.user
  end

  def post_belongs_to_user
    return if post.blank? || user.blank?
    return if post.user_id == user_id

    errors.add(:post, "は自分の投稿のみ設定できます")
  end
end
