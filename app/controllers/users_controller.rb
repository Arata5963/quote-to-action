class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :edit, :update ]

  def show
    # IDがあれば他ユーザー、なければ自分
    if params[:id]
      @user = User.find(params[:id])
      @is_own_page = user_signed_in? && @user == current_user

      # 自分自身の場合はマイページにリダイレクト
      if @is_own_page
        redirect_to mypage_path
        return
      end

      # 達成カレンダー用データ（月表示）
      today = Date.current
      @calendar_year = today.year
      @calendar_month = today.month

      # 今月の達成データ（サムネイル付き）
      @achievement_data = Achievement.monthly_calendar_data_with_thumbnails(
        @user.id,
        @calendar_year,
        @calendar_month
      )

      # 統計
      @total_achievements = @user.achievements.count
      @current_month_achievements = Achievement.current_month_count(@user.id)

      # 他のユーザーの投稿一覧（そのユーザーがエントリーを持つPost）
      user_post_ids = PostEntry.where(user: @user).select(:post_id).distinct
      @user_posts = Post.where(id: user_post_ids)
                        .includes(:post_entries, :cheers)
                        .recent

      # すきな動画
      @favorite_videos = @user.favorite_videos
    else
      # ログイン必須
      authenticate_user!
      @user = current_user
      @is_own_page = true

      # 達成カレンダー用データ（月表示）
      today = Date.current
      @calendar_year = today.year
      @calendar_month = today.month

      # 今月の達成データ（サムネイル付き）
      @achievement_data = Achievement.monthly_calendar_data_with_thumbnails(
        @user.id,
        @calendar_year,
        @calendar_month
      )

      # 統計
      @total_achievements = @user.achievements.count
      @current_month_achievements = Achievement.current_month_count(@user.id)

      # ユーザーの投稿一覧（自分がエントリーを持つPost）
      user_post_ids = PostEntry.where(user: @user).select(:post_id).distinct
      @user_posts = Post.where(id: user_post_ids)
                        .includes(:post_entries, :cheers)
                        .recent

      # すきな動画
      @favorite_videos = @user.favorite_videos

      # ===== タスクタブ用データ（PostEntry単位） =====
      action_entries = PostEntry.where(user: @user)
                                .where.not(deadline: nil)
                                .includes(:post)

      # 今日のタスク
      @todays_tasks = action_entries.where(achieved_at: nil)
                                    .where(deadline: today)
                                    .order(deadline: :asc)

      # 期限切れタスク
      @overdue_tasks = action_entries.where(achieved_at: nil)
                                     .where("post_entries.deadline < ?", today)
                                     .order(deadline: :asc)

      # 今後のタスク
      @upcoming_tasks = action_entries.where(achieved_at: nil)
                                      .where("post_entries.deadline > ?", today)
                                      .order(deadline: :asc)

      # 達成済みタスク
      @completed_tasks = action_entries.where.not(achieved_at: nil)
                                       .order(achieved_at: :desc)
                                       .limit(20)

      # エントリー統計
      @total_entries = PostEntry.where(user: @user).count

      # 過去30日間の活動データ（草用）
      @activity_data = PostEntry.where(user: @user)
                                .where("created_at >= ?", 30.days.ago)
                                .group("DATE(created_at)")
                                .count

      # 連続記録
      @streak = calculate_streak(@user)
    end
  end

  def edit
    @user = current_user
    build_favorite_videos
  end

  def update
    @user = current_user

    success = false
    ActiveRecord::Base.transaction do
      if @user.update(user_params)
        save_favorite_videos
        success = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if success
      redirect_to mypage_path, notice: "プロフィールを更新しました"
    else
      build_favorite_videos
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid
    build_favorite_videos
    render :edit, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:name, :avatar, :avatar_cache, :favorite_quote, :favorite_quote_url)
  end

  def build_favorite_videos
    @favorite_videos = (1..3).map do |position|
      @user.favorite_videos.find_by(position: position) ||
        @user.favorite_videos.build(position: position)
    end
  end

  def save_favorite_videos
    return unless params[:favorite_videos].present?

    params[:favorite_videos].each do |position, video_params|
      position = position.to_i
      url = video_params[:youtube_url].presence

      existing = @user.favorite_videos.find_by(position: position)

      if url.present?
        if existing
          existing.update!(youtube_url: url)
        else
          @user.favorite_videos.create!(youtube_url: url, position: position)
        end
      elsif existing
        existing.destroy!
      end
    end
  end

  def calculate_streak(user)
    # 過去の活動日を取得（エントリー作成日ベース）
    activity_dates = PostEntry.where(user: user)
                              .select("DATE(created_at) as activity_date")
                              .distinct
                              .order(Arel.sql("DATE(created_at) DESC"))
                              .pluck(Arel.sql("DATE(created_at)"))

    return 0 if activity_dates.empty?

    streak = 0
    today = Date.current
    check_date = today

    # 今日または昨日から連続をカウント
    unless activity_dates.include?(today)
      check_date = today - 1.day
      return 0 unless activity_dates.include?(check_date)
    end

    activity_dates.each do |date|
      if date == check_date
        streak += 1
        check_date -= 1.day
      elsif date < check_date
        break
      end
    end

    streak
  end
end
