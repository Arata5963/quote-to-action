class Reminder < ApplicationRecord
  belongs_to :user
  belongs_to :post

  before_validation :set_user_from_post

  validates :remind_at, presence: true
  validates :post_id, uniqueness: { scope: :user_id, message: "ごとに設定できるリマインダーは1つです" }
  validate :post_belongs_to_user
  validate :remind_at_must_be_future, on: :create

  # 現在時刻に該当するリマインダーを取得
  scope :due_now, -> {
    now = Time.current
    where(remind_at: now.beginning_of_minute..now.end_of_minute)
  }

  # 達成済みでない投稿のリマインダーのみ
  scope :active, -> { joins(:post).where(posts: { achieved_at: nil }) }

  # 送信対象（現在時刻かつアクティブ）
  scope :sendable, -> { due_now.active }

  private

  def set_user_from_post
    self.user ||= post&.user
  end

  def post_belongs_to_user
    return if post.blank? || user.blank?
    return if post.user_id == user_id

    errors.add(:post, "は自分の投稿のみ設定できます")
  end

  def remind_at_must_be_future
    return if remind_at.blank?
    return if remind_at > Time.current

    errors.add(:remind_at, "は現在より未来の日時を指定してください")
  end
end
