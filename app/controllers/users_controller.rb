class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user

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
