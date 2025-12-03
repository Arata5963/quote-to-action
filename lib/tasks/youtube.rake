# frozen_string_literal: true

namespace :youtube do
  desc "既存の投稿に対してYouTube情報を一括取得"
  task fetch_all: :environment do
    posts = Post.where(youtube_title: nil).where.not(youtube_url: nil)
    total = posts.count

    puts "YouTube情報を取得します: #{total}件"

    posts.find_each.with_index(1) do |post, index|
      info = YoutubeService.fetch_video_info(post.youtube_url)

      if info
        post.update_columns(
          youtube_title: info[:title],
          youtube_channel_name: info[:channel_name]
        )
        puts "[#{index}/#{total}] Post##{post.id}: #{info[:title]}"
      else
        puts "[#{index}/#{total}] Post##{post.id}: 取得失敗"
      end

      # API制限を考慮して少し待機
      sleep 0.1
    end

    puts "完了しました"
  end
end
