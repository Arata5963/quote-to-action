require 'rails_helper'

RSpec.describe 'UserBadges', type: :request do
  let(:user) { create(:user) }

  describe 'GET /badges' do
    context 'ログインしている場合' do
      before do
        sign_in user
        # バッジを作成
        user.user_badges.create!(badge_key: 'first_step', awarded_at: Time.current)
      end

      it 'バッジ一覧ページが表示される' do
        get user_badges_path
        expect(response).to have_http_status(:success)
      end

      it 'バッジページの主要要素が表示される' do
        get user_badges_path
        expect(response.body).to include('マイバッジ')
        expect(response.body).to include('獲得済み')
        expect(response.body).to include('未獲得')
      end

      it '獲得数が表示される' do
        get user_badges_path
        # 1個獲得していることを確認
        expect(response.body).to match(/獲得済み.*1/m)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        get user_badges_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
