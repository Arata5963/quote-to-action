module AchievementsHelper
  # 月のカレンダーデータを生成（空白セル含む・サムネイル対応）
  # @param achievement_data [Hash] 日付 => { count:, first_post: } のハッシュ
  # @param year [Integer] 年
  # @param month [Integer] 月
  # @return [Array<Hash>] カレンダー表示用のデータ配列
  def generate_monthly_calendar(achievement_data, year, month)
    calendar_days = []

    # 月の1日を取得
    first_day = Date.new(year, month, 1)
    last_day = first_day.end_of_month

    # 月初の空白セル（日曜=0, 月曜=1, ..., 土曜=6）
    first_wday = first_day.wday
    first_wday.times do
      calendar_days << { type: :blank }
    end

    # 月の日付セル
    (1..last_day.day).each do |day|
      date = Date.new(year, month, day)
      data = achievement_data[date]
      calendar_days << {
        type: :day,
        date: date,
        day: day,
        has_achievement: data.present?,
        achievement_count: data&.dig(:count) || 0,
        thumbnail_url: data&.dig(:first_post)&.youtube_thumbnail_url(size: :default),
        post: data&.dig(:first_post)
      }
    end

    # 月末の空白セル（7の倍数になるまで）
    remaining = 7 - (calendar_days.size % 7)
    if remaining < 7
      remaining.times do
        calendar_days << { type: :blank }
      end
    end

    calendar_days
  end

  # 曜日ヘッダー（日曜始まり）
  # @return [Array<String>] 曜日の配列
  def weekday_headers
    %w[日 月 火 水 木 金 土]
  end
end
