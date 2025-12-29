FactoryBot.define do
  factory :cheer do
    association :user
    association :post
  end
end
