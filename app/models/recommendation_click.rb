# app/models/recommendation_click.rb
# 布教経由のYouTubeクリックを記録するモデル
class RecommendationClick < ApplicationRecord
  belongs_to :post
  belongs_to :user

  # 同じユーザーが同じ投稿に複数回クリックは不可
  validates :user_id, uniqueness: { scope: :post_id }

  # クリックを記録（投稿者本人は除外、重複は無視）
  def self.record_click(post:, user:)
    return false if user.nil?
    return false if post.user_id == user.id  # 本人除外

    create(post: post, user: user)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # 既にクリック済みの場合は無視
    false
  end
end
