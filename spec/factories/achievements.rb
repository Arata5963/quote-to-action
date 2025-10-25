# spec/factories/achievements.rb
FactoryBot.define do
  factory :achievement do
    association :user
    association :post
    awarded_at { Date.current }
  end
end
