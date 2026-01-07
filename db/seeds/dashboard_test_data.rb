# マイページダッシュボード用テストデータ
user = User.find(8)  # テストユーザー
puts "ユーザー: #{user.name}"

# 過去30日間にわたってエントリーを追加
30.downto(0) do |days_ago|
  date = Date.current - days_ago.days

  # ランダムにいくつかのエントリーを追加（0〜4件）
  rand(0..4).times do
    # 既存の投稿からランダムに選択
    post = user.posts.sample
    next unless post

    # メモと引用のみ（actionとblogはバリデーションが複雑なため）
    entry_type = [:key_point, :quote].sample

    PostEntry.create!(
      post: post,
      entry_type: entry_type,
      content: case entry_type
               when :key_point then "テストメモ #{date}"
               when :quote then "「テスト引用 #{date}」"
               end,
      created_at: date.to_time + rand(0..23).hours,
      updated_at: date.to_time + rand(0..23).hours
    )
  end
end

# アクションを追加（deadlineが必要）
10.times do |i|
  post = user.posts.sample
  next unless post

  created_date = Date.current - rand(0..20).days
  PostEntry.create!(
    post: post,
    entry_type: :action,
    content: "アクションプラン #{i + 1}",
    deadline: created_date + rand(1..10).days,
    achieved_at: [nil, Time.current].sample,
    created_at: created_date.to_time,
    updated_at: created_date.to_time
  )
end

# ブログを追加（titleが必要）
5.times do |i|
  post = user.posts.sample
  next unless post

  created_date = Date.current - rand(0..20).days
  PostEntry.create!(
    post: post,
    entry_type: :blog,
    title: "ブログ記事タイトル #{i + 1}",
    content: "ブログ内容 #{i + 1}",
    created_at: created_date.to_time,
    updated_at: created_date.to_time
  )
end

# 今日のタスク用のアクションを追加
3.times do |i|
  post = user.posts.sample
  next unless post

  PostEntry.create!(
    post: post,
    entry_type: :action,
    content: "今日やるべきタスク #{i + 1}",
    deadline: Date.current,
    achieved_at: nil,
    created_at: Time.current,
    updated_at: Time.current
  )
end

# 期限切れタスク用のアクションを追加
2.times do |i|
  post = user.posts.sample
  next unless post

  PostEntry.create!(
    post: post,
    entry_type: :action,
    content: "期限切れタスク #{i + 1}",
    deadline: Date.current - (i + 1).days,
    achieved_at: nil,
    created_at: 3.days.ago,
    updated_at: 3.days.ago
  )
end

# 統計を表示
puts "エントリー総数: #{PostEntry.where(post_id: user.post_ids).count}"
puts "メモ: #{PostEntry.where(post_id: user.post_ids, entry_type: :key_point).count}"
puts "引用: #{PostEntry.where(post_id: user.post_ids, entry_type: :quote).count}"
puts "アクション: #{PostEntry.where(post_id: user.post_ids, entry_type: :action).count}"
puts "ブログ: #{PostEntry.where(post_id: user.post_ids, entry_type: :blog).count}"
