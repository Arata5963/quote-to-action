# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user
  has_one :reminder, dependent: :destroy
  has_many :achievements, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  accepts_nested_attributes_for :reminder, allow_destroy: true, reject_if: :all_blank

  scope :recent, -> { order(created_at: :desc) }

  before_save :fetch_youtube_info, if: :should_fetch_youtube_info?

  validates :trigger_content, presence: true, length: { minimum: 1, maximum: 100 }
  validates :action_plan, presence: true, length: { minimum: 1, maximum: 100 }

  # YouTube URL検証（必須）
  validates :youtube_url, presence: true
  validates :youtube_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+},
    message: "は有効なYouTube URLを入力してください"
  }

  # YouTube公式カテゴリEnum
  enum :category, {
    film_animation: 1,
    autos_vehicles: 2,
    music: 10,
    pets_animals: 15,
    sports: 17,
    travel_events: 19,
    gaming: 20,
    people_blogs: 22,
    comedy: 23,
    entertainment: 24,
    news_politics: 25,
    howto_style: 26,
    education: 27,
    science_technology: 28,
    nonprofits_activism: 29
  }, prefix: true

  validates :category, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[trigger_content action_plan youtube_title youtube_channel_name created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user achievements]
  end

  def liked_by?(user)
    likes.exists?(user_id: user.id)
  end

  # YouTube動画ID抽出
  def youtube_video_id
    return nil unless youtube_url.present?

    if youtube_url.include?("youtube.com/watch")
      URI.parse(youtube_url).query&.split("&")
         &.find { |p| p.start_with?("v=") }
         &.delete_prefix("v=")
    elsif youtube_url.include?("youtu.be/")
      youtube_url.split("youtu.be/").last&.split("?")&.first
    end
  rescue URI::InvalidURIError
    nil
  end

  # YouTubeサムネイルURL取得
  def youtube_thumbnail_url(size: :mqdefault)
    return nil unless youtube_video_id

    "https://img.youtube.com/vi/#{youtube_video_id}/#{size}.jpg"
  end

  # YouTube埋め込みURL取得
  def youtube_embed_url
    return nil unless youtube_video_id

    "https://www.youtube.com/embed/#{youtube_video_id}"
  end

  # 達成済みかどうか
  def achieved?
    achieved_at.present?
  end

  # 達成する
  def achieve!
    update!(achieved_at: Time.current) unless achieved?
  end

  private

  # YouTube情報を取得すべきかどうか判定
  def should_fetch_youtube_info?
    return false if youtube_url.blank?

    new_record? || youtube_url_changed?
  end

  # YouTube APIから動画情報を取得してセット
  def fetch_youtube_info
    info = YoutubeService.fetch_video_info(youtube_url)
    return if info.nil?

    self.youtube_title = info[:title]
    self.youtube_channel_name = info[:channel_name]
  end
end
