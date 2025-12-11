class Achievement < ApplicationRecord
  belongs_to :user
  belongs_to :post

  # タスク型：1投稿につき1ユーザー1回のみ達成可能
  validates :achieved_at, presence: true
  validates :post_id, uniqueness: {
    scope: :user_id,
    message: "既に達成済みです"
  }

  scope :today, -> { where(achieved_at: Date.current) }
  scope :recent, -> { order(achieved_at: :desc) }

  # 特定ユーザーの特定月の達成を日付ごとにグループ化
  # @param user_id [Integer] ユーザーID
  # @param year [Integer] 年（例: 2024）
  # @param month [Integer] 月（例: 12）
  # @return [Hash] { Date => Integer } 日付と達成数のハッシュ
  scope :monthly_calendar_data, ->(user_id, year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    where(user_id: user_id)
      .where(achieved_at: start_date..end_date)
      .group(:achieved_at)
      .count
  }

  # 特定ユーザーの今月の達成数を取得
  # @param user_id [Integer] ユーザーID
  # @return [Integer] 今月の達成数
  scope :current_month_count, ->(user_id) {
    today = Date.current
    where(user_id: user_id)
      .where(achieved_at: today.beginning_of_month..today.end_of_month)
      .count
  }
end
