require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:user) { create(:user) }

  describe 'GET /mypage' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'マイページが表示される' do
        get mypage_path
        expect(response).to have_http_status(:success)
      end

      it 'マイページの主要要素が表示される' do
        get mypage_path
        expect(response.body).to include('プロフィール')
        expect(response.body).to include('達成済み')
        expect(response.body).to include('みただけ？')
        expect(response.body).to include('達成カレンダー')
      end

      it '編集リンクが表示される' do
        get mypage_path
        expect(response.body).to include('編集')
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        get mypage_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /edit_profile' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'プロフィール編集ページが表示される' do
        get edit_profile_path
        expect(response).to have_http_status(:success)
      end

      it 'プロフィール編集フォームが表示される' do
        get edit_profile_path
        expect(response.body).to include('プロフィール編集')
        expect(response.body).to include('プロフィール画像')
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        get edit_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /mypage' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'プロフィールを更新できる' do
        patch mypage_path, params: { user: { name: 'テストユーザー' } }

        expect(response).to redirect_to(mypage_path)
        follow_redirect!
        expect(response.body).to include('プロフィールを更新しました')
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        patch mypage_path, params: { user: { name: 'テストユーザー' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
