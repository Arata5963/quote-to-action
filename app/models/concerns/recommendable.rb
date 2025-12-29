# app/models/concerns/recommendable.rb
module Recommendable
  extend ActiveSupport::Concern

  # 推薦投稿を取得
  # 他ユーザーの投稿をランダムに取得
  def recommended_posts(limit: 3)
    return Post.none if limit <= 0

    Post.where.not(user_id: user_id)
        .where.not(id: id)
        .order(Arel.sql("RANDOM()"))
        .limit(limit)
        .to_a
  end
end
