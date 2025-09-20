# app/controllers/achievements_controller.rb
class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    @achievement = current_user.achievements.new(
      post: @post,
      awarded_at: Date.current
    )
    
    awarded_badge = nil
    
    ActiveRecord::Base.transaction do
      if @achievement.save
        # ランダムバッジ付与（1日1個制限）
        badge_data = random_available_badge(current_user)
        if badge_data
          awarded_badge = current_user.user_badges.create!(
            badge_key: badge_data[:key],
            awarded_at: Time.current
          )
        end
      else
        raise ActiveRecord::Rollback
      end
    end
    
    if @achievement.persisted?
      if awarded_badge
        redirect_to @post, notice: "達成を記録しました！新しいバッジ「#{awarded_badge.badge_name}」を獲得しました！"
      else
        redirect_to @post, notice: t("achievements.create.success")
      end
    else
      redirect_to @post, alert: @achievement.errors.full_messages.first
    end
  end

  def destroy
    @achievement = current_user.achievements.today.find_by(post: @post)
    
    if @achievement
      ActiveRecord::Base.transaction do
        # 同じ日付条件で統一
        same_day_achievements = current_user.achievements.where(awarded_at: @achievement.awarded_at.all_day)
        
        if same_day_achievements.count == 1  # 削除対象が最後の1件
          # バッジも同時削除
          current_user.user_badges.where(awarded_at: @achievement.awarded_at.all_day).destroy_all
        end
        
        @achievement.destroy
      end
      redirect_to @post, notice: t("achievements.destroy.success")
    else
      redirect_to @post, alert: t("achievements.destroy.not_found")
    end
  end

  private
  
  def set_post
    @post = current_user.posts.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end
end