# spec/factories/post_comparisons.rb
FactoryBot.define do
  factory :post_comparison do
    association :source_post, factory: :post
    association :target_post, factory: :post
    reason { nil }

    trait :with_reason do
      reason { "これらの動画は同じトピックについて異なる視点から解説している" }
    end
  end
end
