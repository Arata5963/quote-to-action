class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @posts = current_user.posts.includes(:achievements).order(created_at: :desc)
    
    @total_achievements = current_user.achievements.count
    @today_achievements = current_user.achievements.today.count
    @total_posts = current_user.posts.count
  end
end