FactoryBot.define do
  factory :comment do
    association :user
    association :post
    content { Faker::Lorem.sentence(word_count: 20) }
  end
end
