class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @posts = current_user.posts.includes(:achievements).order(created_at: :desc)

    @total_achievements = current_user.achievements.count
    @today_achievements = current_user.achievements.today.count
    @total_posts = current_user.posts.count
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
    params.require(:user).permit(:avatar, :avatar_cache)
  end
end
