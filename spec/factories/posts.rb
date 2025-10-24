# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    # 必須項目のみ
    association :user
    trigger_content { Faker::Lorem.sentence(word_count: 10) }
    action_plan { Faker::Lorem.sentence(word_count: 10) }
    category { Post.categories.keys.sample }

    # 任意項目
    trait :with_url do
      related_url { Faker::Internet.url }
    end

    trait :with_image do
      image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample_post.jpg"), "image/jpeg") }
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