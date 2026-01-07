# テスト用達成データ
user = User.find(8)
puts "ユーザー: #{user.name}"
puts "現在の達成数: #{user.achievements.count}"

# 今月の達成を追加
today = Date.current
10.times do |i|
  post = user.posts.sample
  next unless post

  date = today - rand(0..20).days

  # 既存の達成があればスキップ
  next if Achievement.exists?(user: user, post: post)

  Achievement.create!(
    user: user,
    post: post,
    achieved_at: date
  )
  puts "達成追加: #{date} - #{post.youtube_title&.truncate(30)}"
end

puts "達成数（更新後）: #{user.achievements.count}"
