# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :achievements, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  # ユーザーは複数のコメントを持つ
  has_many :comments, dependent: :destroy

  mount_uploader :avatar, ImageUploader

  def total_achievements_count
    achievements.count
  end

  def available_badges_count
    BADGE_POOL.size - user_badges.count
  end
end
