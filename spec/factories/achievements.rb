# spec/factories/achievements.rb
FactoryBot.define do
  factory :achievement do
    association :user
    association :post
    achieved_at { Date.current }
  end
end
