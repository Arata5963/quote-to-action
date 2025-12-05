# spec/factories/reminders.rb
FactoryBot.define do
  factory :reminder do
    remind_at { 1.day.from_now }

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

    # 今日中のリマインダー
    trait :today do
      remind_at { 1.hour.from_now }
    end

    # 来週のリマインダー
    trait :next_week do
      remind_at { 1.week.from_now }
    end

    # 送信対象（現在時刻）
    trait :due_now do
      remind_at { Time.current }
    end
  end
end
