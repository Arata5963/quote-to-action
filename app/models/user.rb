# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :posts, dependent: :destroy
  has_many :achievements, dependent: :destroy
  has_many :user_badges, dependent: :destroy  # 追加

  mount_uploader :avatar, ImageUploader

  # 追加：ユーザーの合計達成数
  def total_achievements_count
    achievements.count
  end
  
  # 追加：未獲得バッジ数
  def available_badges_count
    BADGE_POOL.size - user_badges.count
  end
end