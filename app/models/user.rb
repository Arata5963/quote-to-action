class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :posts, dependent: :destroy
  has_many :achievements, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  mount_uploader :avatar, ImageUploader

  # 既存メールがあればそれにGoogle情報を連携、なければ新規作成
  def self.from_omniauth(auth)
    # 1) すでに連携済みならそのまま返す
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # 2) 同じメールの既存ユーザーを連携
    user = find_by(email: auth.info.email)
    if user
      user.update!(provider: auth.provider, uid: auth.uid)
      return user
    end

    # 3) なければ新規作成
    create!(
      email:    auth.info.email,
      password: Devise.friendly_token[0, 20],
      provider: auth.provider,
      uid:      auth.uid
    )
  end

  def total_achievements_count
    achievements.count
  end

  def available_badges_count
    BADGE_POOL.size - user_badges.count
  end
end