# app/models/concerns/recommendable.rb
module Recommendable
  extend ActiveSupport::Concern

  # 推薦投稿を取得
  # 同じカテゴリの他ユーザー投稿をランダムに取得し、不足分は他カテゴリから補填
  def recommended_posts(limit: 3)
    return Post.none if limit <= 0

    # Step 1: 同じカテゴリから取得
    same_category_posts = Post.where(category: category)
                              .where.not(user_id: user_id)
                              .where.not(id: id)
                              .order(Arel.sql("RANDOM()"))
                              .limit(limit)
                              .to_a

    return same_category_posts if same_category_posts.size >= limit

    # Step 2: 不足分を他カテゴリから補填
    remaining = limit - same_category_posts.size
    exclude_ids = same_category_posts.pluck(:id) + [ id ]

    other_category_posts = Post.where.not(id: exclude_ids)
                               .where.not(user_id: user_id)
                               .order(Arel.sql("RANDOM()"))
                               .limit(remaining)
                               .to_a

    same_category_posts + other_category_posts
  end
end
