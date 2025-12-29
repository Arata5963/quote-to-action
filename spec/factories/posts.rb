# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    # 必須項目
    association :user
    action_plan { Faker::Lorem.sentence(word_count: 10) }
    deadline { Date.current + 7.days }
    youtube_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}" }
    youtube_title { Faker::Lorem.sentence(word_count: 5) }
    youtube_channel_name { Faker::Name.name }

    # 達成済み
    trait :achieved do
      achieved_at { Time.current }
    end

    # 期日が近い（3日以内）
    trait :deadline_near do
      deadline { Date.current + rand(0..3).days }
    end

    # 期日超過
    trait :deadline_passed do
      deadline { Date.current - rand(1..7).days }
    end

    # 期日なし
    trait :without_deadline do
      deadline { nil }
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
