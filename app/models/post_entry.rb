# app/models/post_entry.rb
class PostEntry < ApplicationRecord
  belongs_to :post
  belongs_to :user

  enum :entry_type, {
    key_point: 0,       # 📝 メモ
    action: 1,          # 🎯 アクション
    quote: 2,           # 💬 引用
    blog: 3,            # 📰 ブログ
    recommendation: 4   # 📣 布教
  }

  # 満足度の定数
  SATISFACTION_RATINGS = (1..5).freeze
  SATISFACTION_LABELS = {
    1 => "不満",
    2 => "やや不満",
    3 => "普通",
    4 => "満足",
    5 => "とても満足"
  }.freeze

  # 布教おすすめ度の定数
  RECOMMENDATION_LEVELS = (1..5).freeze

  # バリデーション
  validates :entry_type, presence: true
  validates :content, presence: true, unless: :recommendation?
  validates :deadline, presence: true, if: :action?
  validates :title, presence: true, if: :blog?
  validates :satisfaction_rating, inclusion: { in: SATISFACTION_RATINGS }, allow_nil: true

  # 種類ごとに1つまで（同一ユーザー + 同一投稿 + 同一種類）
  validates :entry_type, uniqueness: {
    scope: [:post_id, :user_id],
    message: "この種類のエントリーは既に投稿済みです"
  }, if: -> { user_id.present? }

  # 布教バリデーション
  validates :recommendation_level, presence: true, inclusion: { in: RECOMMENDATION_LEVELS }, if: :recommendation?
  validates :recommendation_point, presence: true, if: :recommendation?

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :actions_not_achieved, -> { where(entry_type: :action, achieved_at: nil) }
  scope :with_satisfaction, -> { where.not(satisfaction_rating: nil) }
  scope :blogs, -> { where(entry_type: :blog) }
  scope :draft_blogs, -> { blogs.where(published_at: nil) }
  scope :published_blogs, -> { blogs.where.not(published_at: nil) }

  # 達成済みか
  def achieved?
    achieved_at.present?
  end

  # 達成をトグル
  def achieve!
    return false unless action?
    if achieved?
      update!(achieved_at: nil)
    else
      update!(achieved_at: Time.current)
    end
  end

  # 満足度ラベル
  def satisfaction_label
    SATISFACTION_LABELS[satisfaction_rating]
  end

  # 満足度の星表示（★☆形式）
  def satisfaction_stars
    return nil unless satisfaction_rating
    "★" * satisfaction_rating + "☆" * (5 - satisfaction_rating)
  end

  # ブログが下書きか
  def draft?
    blog? && published_at.nil?
  end

  # ブログが公開済みか
  def published?
    blog? && published_at.present?
  end

  # ブログを公開する
  def publish!
    return false unless blog?
    update!(published_at: Time.current)
  end

  # ブログを非公開にする（下書きに戻す）
  def unpublish!
    return false unless blog?
    update!(published_at: nil)
  end

  # 布教のおすすめ度を🔥で表示
  def recommendation_fires
    return nil unless recommendation?
    "🔥" * (recommendation_level || 0)
  end

  # 匿名表示かどうか
  def display_anonymous?
    anonymous?
  end

  # 表示用ユーザー名（匿名なら「匿名」を返す）
  def display_user_name
    anonymous? ? "匿名" : user&.name
  end

  # 表示用アバター（匿名ならnilを返す）
  def display_avatar
    anonymous? ? nil : user&.avatar
  end
end
