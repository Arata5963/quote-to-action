# app/controllers/achievements_controller.rb
class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    # タスク型：Postモデル側で達成管理
    if @post.achieved?
      respond_to do |format|
        format.html { redirect_to @post, alert: "既に達成済みです" }
        format.turbo_stream { redirect_to @post, alert: "既に達成済みです" }
      end
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

    # 推薦投稿を取得
    @recommended_posts = @post.recommended_posts(limit: 3)

    respond_to do |format|
      format.html { redirect_to @post, notice: t("achievements.create.success") }
      format.turbo_stream
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to @post, alert: e.message }
      format.turbo_stream { redirect_to @post, alert: e.message }
    end
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
