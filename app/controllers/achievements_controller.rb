class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    # タスク型：Postモデル側で達成管理
    if @post.achieved?
      redirect_to @post, alert: "既に達成済みです"
      return
    end

    awarded_badge = nil

    ActiveRecord::Base.transaction do
      @post.achieve!

      # Achievement記録も残す（統計用）
      @achievement = current_user.achievements.create!(
        post: @post,
        achieved_at: Date.current
      )

      # バッジ獲得処理
      badge_data = random_available_badge(current_user)
      if badge_data
        awarded_badge = current_user.user_badges.create!(
          badge_key: badge_data[:key],
          awarded_at: Time.current
        )
      end
    end

    if awarded_badge
      redirect_to @post, notice: "達成を記録しました！新しいバッジ「#{awarded_badge.badge_name}」を獲得しました！"
    else
      redirect_to @post, notice: t("achievements.create.success")
    end
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
