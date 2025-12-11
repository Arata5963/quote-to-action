module AchievementsHelper
  # 月のカレンダーデータを生成（空白セル含む）
  # @param achievement_counts [Hash] 日付 => 達成数のハッシュ
  # @param year [Integer] 年
  # @param month [Integer] 月
  # @return [Array<Hash>] カレンダー表示用のデータ配列
  def generate_monthly_calendar(achievement_counts, year, month)
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
      calendar_days << {
        type: :day,
        date: date,
        day: day,
        has_achievement: achievement_counts.key?(date)
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
