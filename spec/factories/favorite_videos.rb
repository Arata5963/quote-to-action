FactoryBot.define do
  factory :favorite_video do
    association :user
    sequence(:youtube_url) { |n| "https://www.youtube.com/watch?v=video#{n}" }
    youtube_title { "テスト動画タイトル" }
    youtube_channel_name { "テストチャンネル" }
    sequence(:position) { |n| ((n - 1) % 3) + 1 }
  end
end
