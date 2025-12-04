class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    # タスク型：Postモデル側で達成管理
    if @post.achieved?
      redirect_to @post, alert: "既に達成済みです"
      return
    end

    ActiveRecord::Base.transaction do
      @post.achieve!

      # Achievement記録も残す（統計用）
      current_user.achievements.create!(
        post: @post,
        achieved_at: Date.current
      )
    end

    redirect_to @post, notice: t("achievements.create.success")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @post, alert: e.message
  end

  def destroy
    # タスク型では達成の取り消しは不可
    redirect_to @post, alert: "達成記録は取り消せません"
  end

  private

  def set_post
    @post = current_user.posts.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end
end
