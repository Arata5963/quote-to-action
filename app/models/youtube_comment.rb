# app/models/youtube_comment.rb
# YouTubeコメントを保存するモデル（AI分類・ブックマーク用）
class YoutubeComment < ApplicationRecord
  belongs_to :post
  has_many :comment_bookmarks, dependent: :destroy
  has_many :bookmarked_by_users, through: :comment_bookmarks, source: :user

  # カテゴリ定義
  CATEGORIES = {
    funny: { label: "面白い", emoji: "😂" },
    informative: { label: "ためになる", emoji: "💡" },
    emotional: { label: "感動", emoji: "😭" },
    relatable: { label: "共感", emoji: "🔥" }
  }.freeze

  validates :youtube_comment_id, presence: true, uniqueness: true
  validates :content, presence: true
  validates :category, inclusion: { in: CATEGORIES.keys.map(&:to_s) }, allow_nil: true

  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_like_count, -> { order(like_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # YouTube直リンクURL
  def youtube_url
    return nil unless post&.youtube_video_id && youtube_comment_id
    "https://www.youtube.com/watch?v=#{post.youtube_video_id}&lc=#{youtube_comment_id}"
  end

  # カテゴリのラベル取得
  def category_label
    CATEGORIES.dig(category&.to_sym, :label)
  end

  # カテゴリの絵文字取得
  def category_emoji
    CATEGORIES.dig(category&.to_sym, :emoji)
  end

  # ユーザーがブックマーク済みか確認
  def bookmarked_by?(user)
    return false unless user
    comment_bookmarks.exists?(user: user)
  end
end
