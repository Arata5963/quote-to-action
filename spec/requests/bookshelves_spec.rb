require 'rails_helper'

RSpec.describe 'Bookshelves', type: :request do
  let(:user) { create(:user, name: 'テストユーザー') }
  let(:other_user) { create(:user, name: '他のユーザー') }

  # ====================
  # GET /bookshelf (自分のフィルム)
  # ====================
  describe 'GET /bookshelf' do
    context 'ログインしている場合' do
      before { sign_in user }

      it 'フィルムが表示される' do
        get bookshelf_path
        expect(response).to have_http_status(:success)
      end

      it 'マイフィルムのタイトルが表示される' do
        get bookshelf_path
        expect(response.body).to include('マイフィルム')
      end

      it '現在の年月が表示される' do
        get bookshelf_path
        expect(response.body).to include(Date.current.strftime('%Y年%-m月'))
      end

      context '達成済み投稿がある場合' do
        let!(:achieved_post) { create(:post, user: user, achieved_at: Time.current) }
        let!(:unachieved_post) { create(:post, user: user, achieved_at: nil) }

        it '達成済み投稿のサムネイルが表示される' do
          get bookshelf_path
          expect(response.body).to include(achieved_post.youtube_thumbnail_url(size: :mqdefault))
        end

        it '未達成投稿は表示されない' do
          get bookshelf_path
          expect(response.body).not_to include(unachieved_post.youtube_thumbnail_url(size: :mqdefault))
        end

        it '投稿詳細へのリンクが表示される' do
          get bookshelf_path
          expect(response.body).to include(post_path(achieved_post))
        end

        it '総達成数が表示される' do
          get bookshelf_path
          expect(response.body).to include('総達成数: 1本')
        end
      end

      context '達成済み投稿がない場合' do
        it '空のフィルムメッセージが表示される' do
          get bookshelf_path
          expect(response.body).to include('この月はまだ達成がありません')
        end

        it '投稿一覧へのリンクが表示される' do
          get bookshelf_path
          expect(response.body).to include('投稿一覧を見る')
          expect(response.body).to include(posts_path)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        get bookshelf_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # GET /users/:id/bookshelf (他ユーザーのフィルム)
  # ====================
  describe 'GET /users/:id/bookshelf' do
    context '他ユーザーのフィルムを見る場合' do
      before { sign_in user }

      it '他ユーザーのフィルムが表示される' do
        get user_bookshelf_path(other_user)
        expect(response).to have_http_status(:success)
      end

      it '他ユーザーの名前が表示される' do
        get user_bookshelf_path(other_user)
        expect(response.body).to include('他のユーザーさんのフィルム')
      end

      context '他ユーザーに達成済み投稿がある場合' do
        let!(:other_achieved_post) { create(:post, user: other_user, achieved_at: Time.current) }

        it '達成済み投稿のサムネイルが表示される' do
          get user_bookshelf_path(other_user)
          expect(response.body).to include(other_achieved_post.youtube_thumbnail_url(size: :mqdefault))
        end
      end
    end

    context '自分自身のIDでアクセスする場合' do
      before { sign_in user }

      it '自分のフィルムにリダイレクトされる' do
        get user_bookshelf_path(user)
        expect(response).to redirect_to(bookshelf_path)
      end
    end

    context 'ログインしていない場合' do
      it '他ユーザーのフィルムを見られる' do
        get user_bookshelf_path(other_user)
        expect(response).to have_http_status(:success)
      end
    end

    context '存在しないユーザーの場合' do
      it 'ルートにリダイレクトされる' do
        get user_bookshelf_path(id: 99999)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ====================
  # 月切り替え機能
  # ====================
  describe '月切り替え機能' do
    before { sign_in user }

    it '前月を指定してアクセスできる' do
      prev_month = Date.current.prev_month
      get bookshelf_path, params: { year: prev_month.year, month: prev_month.month }
      expect(response).to have_http_status(:success)
      expect(response.body).to include(prev_month.strftime('%Y年%-m月'))
    end

    context '過去の月に達成済み投稿がある場合' do
      let!(:past_post) do
        create(:post, user: user, achieved_at: 2.months.ago)
      end

      it 'その月に投稿が表示される' do
        target_date = 2.months.ago.to_date
        get bookshelf_path, params: { year: target_date.year, month: target_date.month }
        expect(response.body).to include(past_post.youtube_thumbnail_url(size: :mqdefault))
      end
    end

    it '未来の月への移動ボタンは無効化される' do
      get bookshelf_path
      expect(response.body).to include('film-month-btn--disabled')
    end
  end

  # ====================
  # 日付別表示
  # ====================
  describe '日付別表示' do
    before { sign_in user }

    it '月の全日付が表示される' do
      get bookshelf_path
      # 今月の日数分の日付ラベルが表示される
      (1..Date.current.end_of_month.day).each do |day|
        expect(response.body).to include("film-day-date\">#{day}</span>")
      end
    end

    context '特定の日に達成済み投稿がある場合' do
      let!(:achieved_post) { create(:post, user: user, achieved_at: Time.current) }

      it 'その日の行にサムネイルが表示される' do
        get bookshelf_path
        expect(response.body).to include(achieved_post.youtube_thumbnail_url(size: :mqdefault))
      end
    end
  end
end
