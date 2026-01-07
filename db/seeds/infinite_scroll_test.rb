# db/seeds/infinite_scroll_test.rb
# 無限スクロールテスト用データ

# 複数のユーザーを作成
users = []
5.times do |i|
  users << User.find_or_create_by!(email: "test#{i + 1}@example.com") do |u|
    u.password = "password123"
    u.name = "テストユーザー#{i + 1}"
  end
end

# 既存の投稿にエントリーを追加
Post.find_each do |post|
  next if post.post_entries.exists?

  entry_types = [:key_point, :quote, :action]
  entry_type = entry_types.sample

  post.post_entries.create!(
    entry_type: entry_type,
    content: case entry_type
             when :key_point then "メモ: この動画から学んだポイントです"
             when :quote then "引用: 「名言や印象に残った言葉」"
             when :action then "アクション: 明日から実践すること"
             end,
    deadline: entry_type == :action ? Date.current + rand(1..30).days : nil
  )
  print "+"
end

# 追加の投稿データを作成（異なるユーザーで）
youtube_data = [
  { id: "dQw4w9WgXcQ", title: "Rick Astley - Never Gonna Give You Up", channel: "Rick Astley" },
  { id: "9bZkp7q19f0", title: "PSY - GANGNAM STYLE", channel: "officialpsy" },
  { id: "kJQP7kiw5Fk", title: "Luis Fonsi - Despacito", channel: "Luis Fonsi" },
  { id: "JGwWNGJdvx8", title: "Ed Sheeran - Shape of You", channel: "Ed Sheeran" },
  { id: "RgKAFK5djSk", title: "Wiz Khalifa - See You Again", channel: "Wiz Khalifa" },
  { id: "OPf0YbXqDm0", title: "Mark Ronson - Uptown Funk", channel: "Mark Ronson" },
  { id: "fJ9rUzIMcZQ", title: "Queen - Bohemian Rhapsody", channel: "Queen" },
  { id: "CevxZvSJLk8", title: "Post Malone - Sunflower", channel: "Post Malone" },
  { id: "hT_nvWreIhg", title: "Maroon 5 - Girls Like You", channel: "Maroon 5" },
  { id: "YQHsXMglC9A", title: "Adele - Hello", channel: "Adele" }
]

count = 0
users.each_with_index do |user, user_idx|
  youtube_data.each_with_index do |data, video_idx|
    # ユニーク制約をチェック
    next if Post.exists?(user: user, youtube_video_id: data[:id])

    post = Post.new(
      user: user,
      youtube_url: "https://www.youtube.com/watch?v=#{data[:id]}",
      youtube_video_id: data[:id],
      youtube_title: "#{data[:title]} (ユーザー#{user_idx + 1})",
      youtube_channel_name: data[:channel],
      created_at: (count + 1).hours.ago
    )

    if post.save(validate: false)
      entry_types = [:key_point, :quote, :action]
      entry_type = entry_types[count % 3]

      post.post_entries.create!(
        entry_type: entry_type,
        content: case entry_type
                 when :key_point then "テストメモ #{count + 1}: この動画から学んだポイントです"
                 when :quote then "テスト引用 #{count + 1}: 「名言や印象に残った言葉」"
                 when :action then "テストアクション #{count + 1}: 明日から実践すること"
                 end,
        deadline: entry_type == :action ? Date.current + rand(1..30).days : nil
      )
      count += 1
      print "."
    end
  end
end

puts "\n#{count}件のテストデータを新規作成しました"
puts "総投稿数: #{Post.count}"
