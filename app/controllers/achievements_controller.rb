class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @achievement = current_user.achievements.new(
      post: @post,
      awarded_at: Date.current
    )
    
    if @achievement.save
      # ja.ymlのメッセージを使用
      redirect_to @post, notice: t("achievements.create.success")
    else
      redirect_to @post, alert: @achievement.errors.full_messages.first
    end
  end

  private
  
  def set_post
    @post = current_user.posts.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    # ja.ymlのメッセージを使用
    redirect_to posts_path, alert: t("posts.not_found")
  end
end