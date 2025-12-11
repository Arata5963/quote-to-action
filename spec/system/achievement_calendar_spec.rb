require 'rails_helper'

RSpec.describe 'Achievement Calendar (Monthly)', type: :system do
  include ActiveSupport::Testing::TimeHelpers

  before do
    driven_by(:rack_test)
  end

  let(:user) { create(:user) }

  around do |example|
    travel_to Date.new(2024, 12, 15) do
      example.run
    end
  end

  before do
    sign_in user
  end

  context '達成データがある場合' do
    before do
      post1 = create(:post, user: user)
      post2 = create(:post, user: user)

      create(:achievement, user: user, post: post1, achieved_at: Date.new(2024, 12, 11))
      create(:achievement, user: user, post: post2, achieved_at: Date.new(2024, 12, 11))
      create(:achievement, user: user, post: create(:post, user: user), achieved_at: Date.new(2024, 12, 5))
    end

    it 'マイページに達成カレンダーが表示される' do
      visit mypage_path

      expect(page).to have_content('達成カレンダー')
      expect(page).to have_content('総達成数')
      expect(page).to have_content('今月の達成')
    end

    it '今月が表示される' do
      visit mypage_path

      expect(page).to have_content('2024年12月')
    end

    it '曜日ヘッダーが表示される' do
      visit mypage_path

      %w[日 月 火 水 木 金 土].each do |weekday|
        expect(page).to have_content(weekday)
      end
    end

    it '統計が正しく表示される' do
      visit mypage_path

      expect(page).to have_content('3') # 総達成数・今月の達成
    end

    it '達成日が塗りつぶされている' do
      visit mypage_path

      # 達成日のセルにbg-accentクラスが適用されている
      expect(page).to have_css('.bg-accent', minimum: 2)
    end

    it '凡例が表示される' do
      visit mypage_path

      expect(page).to have_content('達成あり')
      expect(page).to have_content('達成なし')
    end
  end

  context '達成データがない場合' do
    it 'カレンダーは表示されるが達成数は0' do
      visit mypage_path

      expect(page).to have_content('達成カレンダー')
      expect(page).to have_content('0') # 総達成数・今月の達成
    end
  end
end
