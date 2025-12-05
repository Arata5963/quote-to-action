# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    # 必須項目
    association :user
    action_plan { Faker::Lorem.sentence(word_count: 10) }
    category { Post.categories.keys.sample }
    youtube_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}" }
    youtube_title { Faker::Lorem.sentence(word_count: 5) }
    youtube_channel_name { Faker::Name.name }

    # 達成済み
    trait :achieved do
      achieved_at { Time.current }
    end

    # 関連データ付き
    trait :with_achievements do
      transient do
        achievements_count { 3 }
      end

      after(:create) do |post, evaluator|
        create_list(:achievement, evaluator.achievements_count, post: post, user: post.user)
      end
    end

    trait :with_comments do
      transient do
        comments_count { 3 }
      end

      after(:create) do |post, evaluator|
        create_list(:comment, evaluator.comments_count, post: post)
      end
    end
  end
end
