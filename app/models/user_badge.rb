# app/models/user_badge.rb
class UserBadge < ApplicationRecord
  belongs_to :user

  validates :badge_key, presence: true
  validates :badge_key, uniqueness: { scope: :user_id }

  scope :recent, -> { order(awarded_at: :desc) }

  def badge_info
    BADGE_POOL.find { |badge| badge[:key] == badge_key }
  end

  def badge_name
    badge_info&.dig(:name) || "不明なバッジ"
  end

  def badge_svg
    badge_info&.dig(:svg) || ""
  end

  def description
    badge_info&.dig(:description) || ""
  end
end
