# app/controllers/stats_controller.rb
class StatsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @posts = @user.posts.includes(:post_entries)
    @entries = PostEntry.joins(:post).where(posts: { user_id: @user.id })

    # 基本統計
    @total_posts = @posts.count
    @total_entries = @entries.count

    # 達成率
    @achieved_count = @entries.where.not(achieved_at: nil).count
    @achievement_rate = @total_entries.positive? ? (@achieved_count.to_f / @total_entries * 100).round(1) : 0

    # 期間別統計（過去30日）
    @recent_entries = @entries.where("post_entries.created_at >= ?", 30.days.ago)
    @daily_counts = calculate_daily_counts(@recent_entries)

    # 人気チャンネル（視聴回数TOP5）
    @top_channels = @posts
      .where.not(youtube_channel_name: [nil, ""])
      .group(:youtube_channel_name)
      .order("count_all DESC")
      .limit(5)
      .count

    # ストリーク（連続日数）
    @current_streak = calculate_streak
  end

  private

  def calculate_daily_counts(entries)
    # 過去30日分の日付を生成
    dates = (29.days.ago.to_date..Date.current).to_a

    # エントリーの日別カウントを取得
    counts = entries.group(Arel.sql("DATE(post_entries.created_at)")).count

    # 全ての日付に対してカウントを設定（0を含む）
    dates.map { |date| [date.to_s, counts[date.to_s] || counts[date] || 0] }.to_h
  end

  def calculate_streak
    dates = @entries.where("post_entries.created_at >= ?", 365.days.ago)
                    .distinct
                    .pluck(Arel.sql("DATE(post_entries.created_at)"))
                    .map(&:to_date)
                    .sort
                    .reverse

    return 0 if dates.empty?

    streak = 0
    current_date = Date.current

    # 今日または昨日から連続をカウント
    if dates.include?(current_date) || dates.include?(current_date - 1.day)
      streak = 1
      check_date = dates.include?(current_date) ? current_date - 1.day : current_date - 2.days

      dates.each do |date|
        next if date > check_date

        if date == check_date
          streak += 1
          check_date -= 1.day
        else
          break
        end
      end
    end

    streak
  end
end
