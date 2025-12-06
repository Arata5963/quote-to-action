# spec/requests/posts_spec.rb
require 'rails_helper'

RSpec.describe "Posts", type: :request do
  # ====================
  # GET /posts (一覧表示)
  # ====================
  describe "GET /posts" do
    context "基本的なアクセス" do
      it "正常にアクセスできる" do
        get posts_path
        expect(response).to have_http_status(200)
      end
    end

    context "投稿の表示" do
      it "投稿が表示される" do
        post1 = create(:post, action_plan: "アクション1")
        post2 = create(:post, action_plan: "アクション2")
        post3 = create(:post, action_plan: "アクション3")

        get posts_path

        expect(response.body).to include("アクション1")
        expect(response.body).to include("アクション2")
        expect(response.body).to include("アクション3")
      end

      it "新しい順に表示される" do
        old_post = create(:post, action_plan: "古いアクション", created_at: 2.days.ago)
        new_post = create(:post, action_plan: "新しいアクション", created_at: 1.day.ago)

        get posts_path

        # 新しい投稿が先に表示される（HTML内の出現順）
        old_pos = response.body.index("古いアクション")
        new_pos = response.body.index("新しいアクション")

        expect(new_pos).to be < old_pos
      end
    end

    context "ページネーション" do
      it "1ページ目に20件まで表示される" do
        # 21件の投稿を作成
        21.times { |i| create(:post, action_plan: "アクション#{i}") }

        get posts_path

        # 20件分表示される
        expect(response.body.scan(/アクション\d+/).size).to eq(20)
      end

      it "2ページ目が存在する" do
        # 21件の投稿を作成
        21.times { |i| create(:post, action_plan: "アクション#{i}") }

        get posts_path, params: { page: 2 }

        expect(response).to have_http_status(200)
        # 2ページ目には1件だけ表示される
        expect(response.body.scan(/アクション\d+/).size).to eq(1)
      end
    end

    context "カテゴリ絞り込み" do
      it "特定のカテゴリのみ表示される" do
        music_post = create(:post, action_plan: "音楽アクション", category: "music")
        education_post = create(:post, action_plan: "教育アクション", category: "education")

        get posts_path, params: { category: "music" }

        expect(response.body).to include("音楽アクション")
        expect(response.body).not_to include("教育アクション")
      end
    end

    context "タブ絞り込み" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }

      before do
        sign_in user
      end

      it "「自分」タブで自分の投稿のみ表示される" do
        my_post = create(:post, user: user, action_plan: "自分のアクション")
        others_post = create(:post, user: other_user, action_plan: "他人のアクション")

        get posts_path, params: { tab: "mine" }

        expect(response.body).to include("自分のアクション")
        expect(response.body).not_to include("他人のアクション")
      end
    end
  end

  # ====================
  # GET /posts/:id (詳細表示)
  # ====================
  describe "GET /posts/:id" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post, user: user, action_plan: "テストアクション") }

    context "投稿が存在する場合" do
      it "投稿の詳細が表示される" do
        get post_path(post_record)

        expect(response).to have_http_status(200)
        expect(response.body).to include("テストアクション")
      end

      it "コメントが表示される" do
        comment = create(:comment, post: post_record, content: "テストコメント")

        get post_path(post_record)

        expect(response.body).to include("テストコメント")
      end

      it "達成回数が表示される" do
        # タスク型: 1投稿1達成
        create(:achievement, post: post_record, user: user, achieved_at: Date.current)

        get post_path(post_record)

        # 達成回数の表示を確認（タスク型なので1回）
        expect(response.body).to include("1")
      end
    end

    context "投稿が存在しない場合" do
      it "404エラーにならず一覧ページにリダイレクト" do
        get post_path(id: 99999)

        expect(response).to redirect_to(posts_path)
        follow_redirect!
        expect(response.body).to include("投稿が見つかりません")
      end
    end
  end

  # ====================
  # GET /posts/new (新規作成フォーム)
  # ====================
  describe "GET /posts/new" do
    context "ログインしている場合" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "新規作成フォームが表示される" do
        get new_post_path

        expect(response).to have_http_status(200)
        expect(response.body).to include("YouTube")
        expect(response.body).to include("アクションプラン")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get new_post_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # POST /posts (新規作成)
  # ====================
  describe "POST /posts" do
    let(:user) { create(:user) }

    context "ログインしている場合" do
      before do
        sign_in user
      end

      context "有効なパラメータの場合" do
        let(:valid_params) do
          {
            post: {
              youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
              action_plan: "新しいアクションプラン",
              category: "music"
            }
          }
        end

        it "投稿を作成できる" do
          expect {
            post posts_path, params: valid_params
          }.to change(Post, :count).by(1)
        end

        it "作成した投稿の詳細ページにリダイレクトされる" do
          post posts_path, params: valid_params

          expect(response).to redirect_to(post_path(Post.last))
          follow_redirect!
          expect(response.body).to include("アクションプラン")
        end

        it "current_userの投稿として作成される" do
          post posts_path, params: valid_params

          expect(Post.last.user).to eq(user)
        end
      end

      context "無効なパラメータの場合" do
        let(:invalid_params) do
          {
            post: {
              youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
              action_plan: "", # 必須項目が空
              category: "music"
            }
          }
        end

        it "投稿が作成されない" do
          expect {
            post posts_path, params: invalid_params
          }.not_to change(Post, :count)
        end

        it "新規作成フォームが再表示される" do
          post posts_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("アクションプラン")
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        post posts_path, params: { post: { action_plan: "test" } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # GET /posts/:id/edit (編集フォーム)
  # ====================
  describe "GET /posts/:id/edit" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:post_record) { create(:post, user: user) }

    context "投稿者本人の場合" do
      before do
        sign_in user
      end

      it "編集フォームが表示される" do
        get edit_post_path(post_record)

        expect(response).to have_http_status(200)
        expect(response.body).to include("編集")
      end
    end

    context "投稿者本人でない場合" do
      before do
        sign_in other_user
      end

      it "詳細ページにリダイレクトされる" do
        get edit_post_path(post_record)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("他のユーザーの投稿は編集・削除できません")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get edit_post_path(post_record)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # PATCH /posts/:id (更新)
  # ====================
  describe "PATCH /posts/:id" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:post_record) { create(:post, user: user, action_plan: "元のアクション") }

    context "投稿者本人の場合" do
      before do
        sign_in user
      end

      context "有効なパラメータの場合" do
        let(:valid_params) do
          {
            post: {
              action_plan: "更新されたアクションプラン"
            }
          }
        end

        it "投稿を更新できる" do
          patch post_path(post_record), params: valid_params

          post_record.reload
          expect(post_record.action_plan).to eq("更新されたアクションプラン")
        end

        it "詳細ページにリダイレクトされる" do
          patch post_path(post_record), params: valid_params

          expect(response).to redirect_to(post_path(post_record))
          follow_redirect!
          expect(response.body).to include("アクションプラン")
        end
      end

      context "無効なパラメータの場合" do
        let(:invalid_params) do
          {
            post: {
              action_plan: "" # 必須項目を空に
            }
          }
        end

        it "投稿が更新されない" do
          patch post_path(post_record), params: invalid_params

          post_record.reload
          expect(post_record.action_plan).to eq("元のアクション")
        end

        it "編集フォームが再表示される" do
          patch post_path(post_record), params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("編集")
        end
      end
    end

    context "投稿者本人でない場合" do
      before do
        sign_in other_user
      end

      it "投稿を更新できない" do
        patch post_path(post_record), params: { post: { action_plan: "他人による更新" } }

        post_record.reload
        expect(post_record.action_plan).to eq("元のアクション")
      end

      it "詳細ページにリダイレクトされる" do
        patch post_path(post_record), params: { post: { action_plan: "他人による更新" } }

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("他のユーザーの投稿は編集・削除できません")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        patch post_path(post_record), params: { post: { action_plan: "更新" } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # DELETE /posts/:id (削除)
  # ====================
  describe "DELETE /posts/:id" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:post_record) { create(:post, user: user) }

    context "投稿者本人の場合" do
      before do
        sign_in user
      end

      it "投稿を削除できる" do
        expect {
          delete post_path(post_record)
        }.to change(Post, :count).by(-1)
      end

      it "一覧ページにリダイレクトされる" do
        delete post_path(post_record)

        expect(response).to redirect_to(posts_path)
        follow_redirect!
        # 実際のアプリのフラッシュメッセージに合わせる
        expect(response.body).to include("きっかけが削除されました")
      end
    end

    context "投稿者本人でない場合" do
      before do
        sign_in other_user
      end

      it "投稿を削除できない" do
        expect {
          delete post_path(post_record)
        }.not_to change(Post, :count)
      end

      it "詳細ページにリダイレクトされる" do
        delete post_path(post_record)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("他のユーザーの投稿は編集・削除できません")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        delete post_path(post_record)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # リマインダー関連
  # ====================
  describe "リマインダー機能" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    describe "POST /posts (リマインダー付き作成)" do
      let(:reminder_datetime) { 1.day.from_now.change(hour: 8, min: 0) }
      let(:valid_params_with_reminder) do
        {
          post: {
            action_plan: "毎日実行する",
            category: "education",
            youtube_url: "https://www.youtube.com/watch?v=test123",
            reminder_attributes: {
              remind_at: reminder_datetime.strftime("%Y-%m-%dT%H:%M")
            }
          }
        }
      end

      it "リマインダー付きで投稿を作成できる" do
        expect {
          post posts_path, params: valid_params_with_reminder
        }.to change(Post, :count).by(1)
                                 .and change(Reminder, :count).by(1)

        created_post = Post.last
        expect(created_post.reminder).to be_present
        expect(created_post.reminder.remind_at).to be_within(1.minute).of(reminder_datetime)
        expect(created_post.reminder.user).to eq(user)
      end

      it "リマインダーなしでも投稿を作成できる" do
        params_without_reminder = {
          post: {
            action_plan: "アクション",
            category: "education",
            youtube_url: "https://www.youtube.com/watch?v=test456"
          }
        }

        expect {
          post posts_path, params: params_without_reminder
        }.to change(Post, :count).by(1)
                                 .and change(Reminder, :count).by(0)
      end
    end

    describe "PATCH /posts/:id (リマインダー更新)" do
      let(:post_record) { create(:post, user: user) }
      let(:reminder_datetime) { 1.day.from_now.change(hour: 9, min: 0) }

      it "リマインダーを追加できる" do
        update_params = {
          post: {
            reminder_attributes: {
              remind_at: reminder_datetime.strftime("%Y-%m-%dT%H:%M")
            }
          }
        }

        expect {
          patch post_path(post_record), params: update_params
        }.to change(Reminder, :count).by(1)

        post_record.reload
        expect(post_record.reminder.remind_at).to be_within(1.minute).of(reminder_datetime)
      end

      context "既存リマインダーがある場合" do
        let!(:existing_reminder) { create(:reminder, user: user, post: post_record, remind_at: 1.day.from_now.change(hour: 8, min: 0), create_post: false) }
        let(:updated_datetime) { 2.days.from_now.change(hour: 21, min: 0) }

        it "リマインダーを更新できる" do
          update_params = {
            post: {
              reminder_attributes: {
                id: existing_reminder.id,
                remind_at: updated_datetime.strftime("%Y-%m-%dT%H:%M")
              }
            }
          }

          patch post_path(post_record), params: update_params

          existing_reminder.reload
          expect(existing_reminder.remind_at).to be_within(1.minute).of(updated_datetime)
        end

        it "リマインダーを削除できる" do
          delete_params = {
            post: {
              reminder_attributes: {
                id: existing_reminder.id,
                _destroy: "1"
              }
            }
          }

          expect {
            patch post_path(post_record), params: delete_params
          }.to change(Reminder, :count).by(-1)

          post_record.reload
          expect(post_record.reminder).to be_nil
        end
      end
    end

    describe "GET /posts/:id (リマインダー表示)" do
      let(:post_record) { create(:post, user: user) }

      context "リマインダーが設定されている場合" do
        let(:reminder_datetime) { 1.day.from_now.change(hour: 7, min: 30) }
        let!(:reminder) { create(:reminder, user: user, post: post_record, remind_at: reminder_datetime, create_post: false) }

        it "リマインダー情報が表示される" do
          get post_path(post_record)

          expect(response.body).to include("リマインダー")
          expect(response.body).to include("に通知")
        end
      end

      context "リマインダーが設定されていない場合" do
        it "リマインダーなしが表示される" do
          get post_path(post_record)

          expect(response.body).to include("リマインダーなし")
        end
      end
    end
  end

  # ====================
  # GET /posts/autocomplete (オートコンプリート)
  # ====================
  describe "GET /posts/autocomplete" do
    let!(:post1) { create(:post, action_plan: "Ruby入門") }
    let!(:post2) { create(:post, action_plan: "Rubyで自動化") }

    it "検索候補を返す" do
      get autocomplete_posts_path, params: { q: "Ruby" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ruby入門")
      expect(response.body).to include("Rubyで自動化")
    end

    it "2文字未満は空を返す" do
      get autocomplete_posts_path, params: { q: "R" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Ruby")
    end

    context "YouTube情報での検索" do
      let!(:post_with_youtube) do
        create(:post,
               action_plan: "学習を続ける",
               youtube_title: "プログラミング入門講座",
               youtube_channel_name: "Tech Channel")
      end

      it "YouTubeタイトルで検索できる" do
        get autocomplete_posts_path, params: { q: "プログラミング" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("プログラミング入門講座")
      end

      it "チャンネル名で検索できる" do
        get autocomplete_posts_path, params: { q: "Tech" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Tech Channel")
      end
    end
  end
end
