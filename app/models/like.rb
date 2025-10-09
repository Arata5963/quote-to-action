class Like < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :user
  belongs_to :post

  # ===== バリデーション =====
  # 同じユーザーが同じ投稿に重複していいねできないようにする
  validates :user_id, uniqueness: { scope: :post_id }
end