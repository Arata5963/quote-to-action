# app/models/favorite_video.rb
class FavoriteVideo < ApplicationRecord
  belongs_to :user

  # バリデーション
  validates :youtube_url, presence: true
  validates :youtube_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},
    message: "は有効なYouTube URLを入力してください"
  }
  validates :position, presence: true,
                       inclusion: { in: 1..3, message: "は1〜3の範囲で指定してください" },
                       uniqueness: { scope: :user_id, message: "は既に使用されています" }

  # ユーザーごとに最大3件
  validate :max_videos_per_user, on: :create

  # YouTube情報の自動取得
  before_save :fetch_youtube_info, if: :should_fetch_youtube_info?

  # 表示順でソート
  scope :ordered, -> { order(:position) }

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

  private

  def max_videos_per_user
    if user && user.favorite_videos.count >= 3
      errors.add(:base, "すきな動画は最大3件までです")
    end
  end

  def should_fetch_youtube_info?
    return false if youtube_url.blank?

    new_record? || youtube_url_changed?
  end

  def fetch_youtube_info
    info = YoutubeService.fetch_video_info(youtube_url)
    return if info.nil?

    self.youtube_title = info[:title]
    self.youtube_channel_name = info[:channel_name]
  end
end
