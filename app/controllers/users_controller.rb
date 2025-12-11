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
      @achieved_posts = @user.posts.where.not(achieved_at: nil).recent
      @unachieved_posts = @user.posts.where(achieved_at: nil).recent
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
      @achieved_posts = @user.posts.where.not(achieved_at: nil).recent
      @unachieved_posts = @user.posts.where(achieved_at: nil).recent
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to mypage_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :avatar, :avatar_cache)
  end
end
