# db/seeds.rb
# 期日中心設計用のテストデータ

puts "Seeding database..."

# 既存データをクリア
puts "Clearing existing data..."
Cheer.destroy_all
Comment.destroy_all
Achievement.destroy_all
Post.destroy_all
FavoriteVideo.destroy_all
User.destroy_all

# テストユーザー作成
puts "Creating test users..."
user1 = User.create!(
  email: "test1@example.com",
  password: "password123",
  name: "テストユーザー1"
)

user2 = User.create!(
  email: "test2@example.com",
  password: "password123",
  name: "テストユーザー2"
)

puts "Created users: #{user1.name}, #{user2.name}"

# YouTube動画のサンプルURL
youtube_urls = [
  "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "https://www.youtube.com/watch?v=jNQXAC9IVRw",
  "https://www.youtube.com/watch?v=9bZkp7q19f0",
  "https://www.youtube.com/watch?v=kJQP7kiw5Fk",
  "https://www.youtube.com/watch?v=RgKAFK5djSk"
]

# 投稿作成
puts "Creating posts..."

# 期日が近い投稿（1日後、2日後）
post1 = Post.create!(
  user: user1,
  youtube_url: youtube_urls[0],
  action_plan: "毎朝5分のストレッチを始める",
  deadline: Date.current + 1.day,
  youtube_title: "朝のストレッチルーティン",
  youtube_channel_name: "健康チャンネル"
)

post2 = Post.create!(
  user: user1,
  youtube_url: youtube_urls[1],
  action_plan: "新しいプログラミング言語を学ぶ",
  deadline: Date.current + 2.days,
  youtube_title: "プログラミング入門",
  youtube_channel_name: "テックチャンネル"
)

# 期日超過の投稿（1日前）
post3 = Post.create!(
  user: user1,
  youtube_url: youtube_urls[2],
  action_plan: "読書習慣を身につける",
  deadline: Date.current - 1.day,
  youtube_title: "読書のすすめ",
  youtube_channel_name: "教育チャンネル"
)

# その他の投稿（7日後）
post4 = Post.create!(
  user: user1,
  youtube_url: youtube_urls[3],
  action_plan: "週3回の運動を習慣化する",
  deadline: Date.current + 7.days,
  youtube_title: "運動の始め方",
  youtube_channel_name: "フィットネスチャンネル"
)

# user2の投稿
post5 = Post.create!(
  user: user2,
  youtube_url: youtube_urls[4],
  action_plan: "英語の勉強を毎日30分する",
  deadline: Date.current + 3.days,
  youtube_title: "英語学習法",
  youtube_channel_name: "語学チャンネル"
)

puts "Created #{Post.count} posts"

# 応援（Cheer）を作成
puts "Creating cheers..."
Cheer.create!(user: user2, post: post1)
Cheer.create!(user: user2, post: post2)
Cheer.create!(user: user1, post: post5)

puts "Created #{Cheer.count} cheers"

# コメントを作成
puts "Creating comments..."
Comment.create!(user: user2, post: post1, content: "応援してます！")
Comment.create!(user: user1, post: post5, content: "一緒に頑張りましょう！")

puts "Created #{Comment.count} comments"

puts "Seeding completed!"
puts "Summary:"
puts "  Users: #{User.count}"
puts "  Posts: #{Post.count}"
puts "  Cheers: #{Cheer.count}"
puts "  Comments: #{Comment.count}"
