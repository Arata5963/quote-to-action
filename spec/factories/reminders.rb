# spec/factories/reminders.rb
FactoryBot.define do
  factory :reminder do
    remind_time { Time.zone.parse("08:00") }

    # ユーザーと投稿の紐づけを自動設定
    transient do
      create_post { true }
    end

    user { association :user }

    after(:build) do |reminder, evaluator|
      if evaluator.create_post && reminder.post.blank?
        reminder.post = build(:post, user: reminder.user)
      end
    end

    # 朝のリマインダー
    trait :morning do
      remind_time { Time.zone.parse("07:00") }
    end

    # 夜のリマインダー
    trait :evening do
      remind_time { Time.zone.parse("21:00") }
    end
  end
end
