require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:user) { create(:user, name: 'テストユーザー') }
  let(:other_user) { create(:user, name: '他のユーザー') }

  # ====================
  # GET /mypage (自分のマイページ)
  # ====================
  describe 'GET /mypage' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'マイページが表示される' do
        get mypage_path
        expect(response).to have_http_status(:success)
      end

      it 'マイページの主要要素が表示される' do
        get mypage_path
        # タブボタンの存在確認
        expect(response.body).to include('達成カレンダー')
        expect(response.body).to include('お気に入り動画')
      end

      it '編集リンクが表示される' do
        get mypage_path
        expect(response.body).to include('編集')
        expect(response.body).to include(edit_profile_path)
      end

      it 'ユーザー名が表示される' do
        get mypage_path
        expect(response.body).to include('テストユーザー')
      end

      context '投稿がある場合' do
        let!(:achieved_post) { create(:post, user: user, achieved_at: Time.current) }
        let!(:unachieved_post) { create(:post, user: user, achieved_at: nil) }

        it '達成カレンダーが表示される' do
          get mypage_path
          # 達成カレンダーのタブが表示される
          expect(response.body).to include('達成カレンダー')
          # 達成ありの凡例が表示される
          expect(response.body).to include('達成あり')
        end
      end

      context '投稿がない場合' do
        it '空の状態が表示される' do
          get mypage_path
          # 達成カレンダータブがデフォルトで表示される
          expect(response.body).to include('達成カレンダー')
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        get mypage_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # GET /users/:id (他ユーザーのプロフィール)
  # ====================
  describe 'GET /users/:id' do
    context '他ユーザーのプロフィールを見る場合' do
      before { sign_in user }

      it '他ユーザーのプロフィールが表示される' do
        get user_profile_path(other_user)
        expect(response).to have_http_status(:success)
      end

      it '他ユーザーの名前が表示される' do
        get user_profile_path(other_user)
        expect(response.body).to include('他のユーザー')
      end

      it '編集リンクは表示されない' do
        get user_profile_path(other_user)
        expect(response.body).not_to include(edit_profile_path)
      end
    end

    context '自分自身のIDでアクセスする場合' do
      before { sign_in user }

      it 'マイページにリダイレクトされる' do
        get user_profile_path(user)
        expect(response).to redirect_to(mypage_path)
      end
    end

    context 'ログインしていない場合' do
      it '他ユーザーのプロフィールを見られる' do
        get user_profile_path(other_user)
        expect(response).to have_http_status(:success)
      end
    end
  end

  # ====================
  # GET /edit_profile
  # ====================
  describe 'GET /edit_profile' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'プロフィール編集ページが表示される' do
        get edit_profile_path
        expect(response).to have_http_status(:success)
      end

      it 'プロフィール編集フォームが表示される' do
        get edit_profile_path
        expect(response.body).to include('プロフィール画像')
        expect(response.body).to include('ユーザー名')
        expect(response.body).to include('更新する')
      end

      it 'キャンセルリンクが表示される' do
        get edit_profile_path
        expect(response.body).to include('キャンセル')
        expect(response.body).to include(mypage_path)
      end

      it '現在のユーザー名が入力欄に表示される' do
        get edit_profile_path
        expect(response.body).to include('テストユーザー')
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        get edit_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # PATCH /mypage (プロフィール更新)
  # ====================
  describe 'PATCH /mypage' do
    context 'ログインしている場合' do
      before { sign_in user }

      context '有効なパラメータの場合' do
        it 'プロフィールを更新できる' do
          patch mypage_path, params: { user: { name: '新しい名前' } }

          expect(response).to redirect_to(mypage_path)
          follow_redirect!
          expect(response.body).to include('プロフィールを更新しました')
        end

        it 'ユーザー名が更新される' do
          expect {
            patch mypage_path, params: { user: { name: '新しい名前' } }
          }.to change { user.reload.name }.from('テストユーザー').to('新しい名前')
        end

        it '名前を空にするとバリデーションエラー（必須項目）' do
          patch mypage_path, params: { user: { name: '' } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(user.reload.name).to eq('テストユーザー') # 変更されていない
        end
      end

      context '無効なパラメータの場合' do
        before do
          # Userモデルにバリデーションがある場合のテスト
          allow_any_instance_of(User).to receive(:update).and_return(false)
          allow_any_instance_of(User).to receive(:errors).and_return(
            double(any?: true, count: 1, full_messages: [ '名前が無効です' ])
          )
        end

        it '422 Unprocessable Entityを返す' do
          patch mypage_path, params: { user: { name: 'テスト' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'エラーメッセージが表示される' do
          patch mypage_path, params: { user: { name: 'テスト' } }
          expect(response.body).to include('エラー')
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        patch mypage_path, params: { user: { name: '新しい名前' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # プロフィール画像関連
  # ====================
  describe 'プロフィール画像' do
    before { sign_in user }

    context '画像をアップロードする場合' do
      let(:image_file) do
        fixture_file_upload(
          Rails.root.join('spec/fixtures/files/test_avatar.png'),
          'image/png'
        )
      end

      before do
        # テスト用の画像ファイルが存在しない場合はスキップ
        skip 'Test image file not found' unless File.exist?(Rails.root.join('spec/fixtures/files/test_avatar.png'))
      end

      it '画像をアップロードできる' do
        patch mypage_path, params: { user: { avatar: image_file } }

        expect(response).to redirect_to(mypage_path)
        expect(user.reload.avatar).to be_present
      end
    end

    context '画像なしの場合' do
      it 'デフォルトアバター用のSVGアイコンが表示される' do
        user.update(avatar: nil)
        get mypage_path

        # SVGアイコンのpath要素（デフォルトアバター）
        expect(response.body).to include('fill-rule="evenodd"')
      end
    end
  end

  # ====================
  # 統計情報
  # ====================
  describe '統計情報' do
    before { sign_in user }

    context '達成記録がある場合' do
      let!(:post_record) { create(:post, user: user, achieved_at: Time.current) }
      let!(:achievement) { create(:achievement, user: user, post: post_record) }

      it 'マイページに達成カレンダータブが表示される' do
        get mypage_path
        expect(response.body).to include('達成カレンダー')
      end
    end
  end
end
