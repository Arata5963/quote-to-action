# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  mount_uploader :image, ImageUploader
  scope :recent, -> { order(created_at: :desc) }

  validates :trigger_content, presence: true, length: { minimum: 1, maximum: 100 }
  validates :action_plan,    presence: true, length: { minimum: 1, maximum: 100 }

  # ===== カテゴリEnum定義（修正版） =====
  enum :category, {
    text: 0,         # 📝 テキスト（本・記事・SNS・メモ）
    video: 1,        # 🎥 映像（動画・映画・ドラマ）
    audio: 2,        # 🎧 音声（ポッドキャスト・ラジオ）
    conversation: 3, # 💬 対話（会話・セミナー・講演）
    experience: 4,   # ✨ 体験（旅行・イベント・実践）
    observation: 5,  # 👀 日常（日常の気づき・自然）
    other: 6         # 📁 その他
  }, prefix: true

  validates :category, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[trigger_content action_plan created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user achievements]
  end

  def liked_by?(user)
    likes.exists?(user_id: user.id)
  end
end