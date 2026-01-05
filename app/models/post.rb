# app/models/post.rb
class Post < ApplicationRecord
  include Recommendable

  belongs_to :user, optional: true
  has_many :achievements, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :cheers, dependent: :destroy
  has_many :post_entries, dependent: :destroy
  has_many :youtube_comments, dependent: :destroy
  has_one :quiz, dependent: :destroy

  # 比較機能: A→B の一方向関係
  # outgoing: この投稿が比較している投稿への関係
  has_many :outgoing_comparisons, class_name: 'PostComparison', foreign_key: :source_post_id, dependent: :destroy
  has_many :compared_posts, through: :outgoing_comparisons, source: :target_post

  # incoming: この投稿を比較している他の投稿からの関係
  has_many :incoming_comparisons, class_name: 'PostComparison', foreign_key: :target_post_id, dependent: :destroy
  has_many :comparing_posts, through: :incoming_comparisons, source: :source_post

  # 布教クリック
  has_many :recommendation_clicks, dependent: :destroy

  scope :recent, -> { order(created_at: :desc) }

  before_save :set_youtube_video_id, if: :should_fetch_youtube_info?
  before_save :fetch_youtube_info, if: :should_fetch_youtube_info?

  # action_planはPostEntry経由で管理するが、互換性のため残す
  validates :action_plan, length: { maximum: 100 }, allow_blank: true

  # YouTube URL検証（必須）
  validates :youtube_url, presence: true
  validates :youtube_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},
    message: "は有効なYouTube URLを入力してください"
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[action_plan youtube_title youtube_channel_name created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user achievements]
  end

  def cheered_by?(user)
    cheers.exists?(user_id: user.id)
  end

  # エントリー関連ヘルパー
  def latest_entry
    post_entries.recent.first
  end

  def entries_count
    post_entries.count
  end

  def has_action_entries?
    post_entries.where(entry_type: :action).exists?
  end

  # 布教エントリーを取得（1件のみ）
  def recommendation_entry
    post_entries.find_by(entry_type: :recommendation)
  end

  # 布教があるかどうか
  def has_recommendation?
    post_entries.exists?(entry_type: :recommendation)
  end

  # 布教クリック数
  def recommendation_click_count
    recommendation_clicks.count
  end

  # 満足度の平均（評価があるエントリーのみ）
  def average_satisfaction_rating
    ratings = post_entries.with_satisfaction.pluck(:satisfaction_rating)
    return nil if ratings.empty?

    (ratings.sum.to_f / ratings.size).round(1)
  end

  # YouTube動画ID取得（保存値優先、なければURLから抽出）
  def youtube_video_id
    read_attribute(:youtube_video_id) || self.class.extract_video_id(youtube_url)
  end

  # クラスメソッド：URLから動画IDを抽出
  def self.extract_video_id(url)
    return nil unless url.present?

    if url.include?("youtube.com/watch")
      URI.parse(url).query&.split("&")
         &.find { |p| p.start_with?("v=") }
         &.delete_prefix("v=")
    elsif url.include?("youtu.be/")
      url.split("youtu.be/").last&.split("?")&.first
    end
  rescue URI::InvalidURIError
    nil
  end

  # 動画IDでPostを検索または作成（ユーザー不問）
  def self.find_or_create_by_video(youtube_url:)
    video_id = extract_video_id(youtube_url)
    return nil unless video_id

    find_or_create_by(youtube_video_id: video_id) do |post|
      post.youtube_url = youtube_url
    end
  end

  # 動画IDでPostを検索または初期化（互換性のため残す）
  def self.find_or_initialize_by_video(youtube_url:)
    video_id = extract_video_id(youtube_url)
    return nil unless video_id

    post = find_or_initialize_by(youtube_video_id: video_id)
    post.youtube_url = youtube_url if post.new_record?
    post
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

  # エントリーを持つユーザー一覧
  def entry_users
    User.where(id: post_entries.select(:user_id).distinct)
  end

  # 特定ユーザーのエントリーを取得
  def entries_by_user(user)
    post_entries.where(user: user)
  end

  # 特定ユーザーがエントリーを持っているか
  def has_entries_by?(user)
    post_entries.exists?(user: user)
  end

  private

  # YouTube情報を取得すべきかどうか判定
  def should_fetch_youtube_info?
    return false if youtube_url.blank?

    new_record? || youtube_url_changed?
  end

  # YouTube動画IDをセット
  def set_youtube_video_id
    self.youtube_video_id = self.class.extract_video_id(youtube_url)
  end

  # YouTube APIから動画情報を取得してセット
  def fetch_youtube_info
    info = YoutubeService.fetch_video_info(youtube_url)
    return if info.nil?

    self.youtube_title = info[:title]
    self.youtube_channel_name = info[:channel_name]
    self.youtube_channel_thumbnail_url = info[:channel_thumbnail_url]
  end
end
