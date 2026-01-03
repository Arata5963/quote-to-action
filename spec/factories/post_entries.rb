# spec/factories/post_entries.rb
FactoryBot.define do
  factory :post_entry do
    association :post
    entry_type { :action }
    content { Faker::Lorem.sentence(word_count: 8) }
    deadline { Date.current + 7.days }

    trait :key_point do
      entry_type { :key_point }
      deadline { nil }
    end

    trait :quote do
      entry_type { :quote }
      deadline { nil }
    end

    trait :action do
      entry_type { :action }
    end

    trait :achieved do
      achieved_at { Time.current }
    end

    trait :with_satisfaction do
      satisfaction_rating { rand(1..5) }
    end

    trait :high_satisfaction do
      satisfaction_rating { 5 }
    end

    trait :low_satisfaction do
      satisfaction_rating { 1 }
    end
  end
end
