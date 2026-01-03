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

      # 今月の達成データ
      @achievement_counts = Achievement.monthly_calendar_data(
        @user.id,
        @calendar_year,
        @calendar_month
      )

      # 統計
      @total_achievements = @user.achievements.count
      @current_month_achievements = Achievement.current_month_count(@user.id)

      # 他のユーザーの投稿一覧（達成済み・未達成）
      @achieved_posts = @user.posts.includes(:user, :post_entries, :cheers, :comments).where.not(achieved_at: nil).recent
      @unachieved_posts = @user.posts.includes(:user, :post_entries, :cheers, :comments).where(achieved_at: nil).recent

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

      # 今月の達成データ
      @achievement_counts = Achievement.monthly_calendar_data(
        @user.id,
        @calendar_year,
        @calendar_month
      )

      # 統計
      @total_achievements = @user.achievements.count
      @current_month_achievements = Achievement.current_month_count(@user.id)

      # ユーザーの投稿一覧（達成済み・未達成）
      @achieved_posts = @user.posts.includes(:user, :post_entries, :cheers, :comments).where.not(achieved_at: nil).recent
      @unachieved_posts = @user.posts.includes(:user, :post_entries, :cheers, :comments).where(achieved_at: nil).recent

      # すきな動画
      @favorite_videos = @user.favorite_videos
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
end
