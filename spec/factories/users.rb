# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    # 基本のユーザー（メール＋パスワードでログイン）
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }

    # Google でログインするユーザー（パスワード不要）
    trait :from_google do
      provider { "google_oauth2" }
      uid { Faker::Number.number(digits: 20).to_s }
      password { nil }
    end

    # アバター画像付きユーザーを作成する trait
    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample_avatar.jpg"), "image/jpeg") }
    end
  end
end
