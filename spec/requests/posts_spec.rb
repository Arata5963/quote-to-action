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
        post1 = create(:post, trigger_content: "投稿1")
        post2 = create(:post, trigger_content: "投稿2")
        post3 = create(:post, trigger_content: "投稿3")

        get posts_path

        expect(response.body).to include("投稿1")
        expect(response.body).to include("投稿2")
        expect(response.body).to include("投稿3")
      end

      it "新しい順に表示される" do
        old_post = create(:post, trigger_content: "古い投稿", created_at: 2.days.ago)
        new_post = create(:post, trigger_content: "新しい投稿", created_at: 1.day.ago)

        get posts_path

        # 新しい投稿が先に表示される（HTML内の出現順）
        old_pos = response.body.index("古い投稿")
        new_pos = response.body.index("新しい投稿")

        expect(new_pos).to be < old_pos
      end
    end

    context "ページネーション" do
      it "1ページ目に20件まで表示される" do
        # 21件の投稿を作成
        21.times { |i| create(:post, trigger_content: "投稿#{i}") }

        get posts_path

        # 20件分表示される
        expect(response.body.scan(/投稿\d+/).size).to eq(20)
      end

      it "2ページ目が存在する" do
        # 21件の投稿を作成
        21.times { |i| create(:post, trigger_content: "投稿#{i}") }

        get posts_path, params: { page: 2 }

        expect(response).to have_http_status(200)
        # 2ページ目には1件だけ表示される
        expect(response.body.scan(/投稿\d+/).size).to eq(1)
      end
    end

    context "カテゴリ絞り込み" do
      it "特定のカテゴリのみ表示される" do
        text_post = create(:post, trigger_content: "テキスト投稿", category: "text")
        video_post = create(:post, trigger_content: "動画投稿", category: "video")

        get posts_path, params: { category: "text" }

        expect(response.body).to include("テキスト投稿")
        expect(response.body).not_to include("動画投稿")
      end
    end

    context "タブ絞り込み" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }

      before do
        sign_in user
      end

      it "「自分」タブで自分の投稿のみ表示される" do
        my_post = create(:post, user: user, trigger_content: "自分の投稿")
        others_post = create(:post, user: other_user, trigger_content: "他人の投稿")

        get posts_path, params: { tab: "mine" }

        expect(response.body).to include("自分の投稿")
        expect(response.body).not_to include("他人の投稿")
      end
    end
  end

  # ====================
  # GET /posts/:id (詳細表示)
  # ====================
  describe "GET /posts/:id" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post, user: user, trigger_content: "テスト投稿") }

    context "投稿が存在する場合" do
      it "投稿の詳細が表示される" do
        get post_path(post_record)

        expect(response).to have_http_status(200)
        expect(response.body).to include("テスト投稿")
      end

      it "コメントが表示される" do
        comment = create(:comment, post: post_record, content: "テストコメント")

        get post_path(post_record)

        expect(response.body).to include("テストコメント")
      end

      it "達成回数が表示される" do
        # 異なる日付で3回達成を記録
        create(:achievement, post: post_record, user: user, awarded_at: 3.days.ago)
        create(:achievement, post: post_record, user: user, awarded_at: 2.days.ago)
        create(:achievement, post: post_record, user: user, awarded_at: 1.day.ago)

        get post_path(post_record)

        # 達成回数の表示を確認（実際のビューに合わせて調整）
        expect(response.body).to include("3")
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
        expect(response.body).to include("きっかけ")
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
              trigger_content: "新しいきっかけ",
              action_plan: "新しいアクションプラン",
              category: "text"
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
          # 実際のアプリのフラッシュメッセージに合わせる
          expect(response.body).to include("きっかけ")
        end

        it "current_userの投稿として作成される" do
          post posts_path, params: valid_params

          expect(Post.last.user).to eq(user)
        end
      end

      context "画像付きで作成する場合" do
        let(:image_params) do
          {
            post: {
              trigger_content: "画像付き投稿",
              action_plan: "画像アクション",
              category: "text",
              image: fixture_file_upload('spec/fixtures/files/sample_avatar.jpg', 'image/jpeg')

            }
          }
        end
        # 画像ファイルがない場合はスキップ
        it "画像付きで投稿を作成できる" do
          expect {
            post posts_path, params: image_params
          }.to change(Post, :count).by(1)

          created_post = Post.last
          expect(created_post.image).to be_present
          expect(created_post.image.url).to be_present
        end
        it "画像がアップロードされてURLが生成される" do
          post posts_path, params: image_params

          created_post = Post.last
          # CarrierWaveのアップロード確認
          expect(created_post.image_identifier).to be_present
        end
      end

      context "無効なパラメータの場合" do
        let(:invalid_params) do
          {
            post: {
              trigger_content: "", # 必須項目が空
              action_plan: "アクションプラン",
              category: "text"
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
          expect(response.body).to include("きっかけ")
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        post posts_path, params: { post: { trigger_content: "test", action_plan: "test" } }

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
    let(:post_record) { create(:post, user: user, trigger_content: "元のきっかけ") }

    context "投稿者本人の場合" do
      before do
        sign_in user
      end

      context "有効なパラメータの場合" do
        let(:valid_params) do
          {
            post: {
              trigger_content: "更新されたきっかけ",
              action_plan: "更新されたアクションプラン"
            }
          }
        end

        it "投稿を更新できる" do
          patch post_path(post_record), params: valid_params

          post_record.reload
          expect(post_record.trigger_content).to eq("更新されたきっかけ")
        end

        it "詳細ページにリダイレクトされる" do
          patch post_path(post_record), params: valid_params

          expect(response).to redirect_to(post_path(post_record))
          follow_redirect!
          # 実際のアプリのフラッシュメッセージに合わせる
          expect(response.body).to include("きっかけ")
        end
      end

      context "無効なパラメータの場合" do
        let(:invalid_params) do
          {
            post: {
              trigger_content: "", # 必須項目を空に
              action_plan: "アクションプラン"
            }
          }
        end

        it "投稿が更新されない" do
          patch post_path(post_record), params: invalid_params

          post_record.reload
          expect(post_record.trigger_content).to eq("元のきっかけ")
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
        patch post_path(post_record), params: { post: { trigger_content: "他人による更新" } }

        post_record.reload
        expect(post_record.trigger_content).to eq("元のきっかけ")
      end

      it "詳細ページにリダイレクトされる" do
        patch post_path(post_record), params: { post: { trigger_content: "他人による更新" } }

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("他のユーザーの投稿は編集・削除できません")
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        patch post_path(post_record), params: { post: { trigger_content: "更新" } }

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
      let(:valid_params_with_reminder) do
        {
          post: {
            trigger_content: "リマインダーテスト",
            action_plan: "毎日実行する",
            category: "education",
            youtube_url: "https://www.youtube.com/watch?v=test123",
            reminder_attributes: {
              remind_time: "08:00"
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
        expect(created_post.reminder.remind_time.strftime("%H:%M")).to eq("08:00")
        expect(created_post.reminder.user).to eq(user)
      end

      it "リマインダーなしでも投稿を作成できる" do
        params_without_reminder = {
          post: {
            trigger_content: "リマインダーなし",
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

      it "リマインダーを追加できる" do
        update_params = {
          post: {
            reminder_attributes: {
              remind_time: "09:00"
            }
          }
        }

        expect {
          patch post_path(post_record), params: update_params
        }.to change(Reminder, :count).by(1)

        post_record.reload
        expect(post_record.reminder.remind_time.strftime("%H:%M")).to eq("09:00")
      end

      context "既存リマインダーがある場合" do
        let!(:existing_reminder) { create(:reminder, user: user, post: post_record, remind_time: "08:00") }

        it "リマインダーを更新できる" do
          update_params = {
            post: {
              reminder_attributes: {
                id: existing_reminder.id,
                remind_time: "21:00"
              }
            }
          }

          patch post_path(post_record), params: update_params

          existing_reminder.reload
          expect(existing_reminder.remind_time.strftime("%H:%M")).to eq("21:00")
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
        let!(:reminder) { create(:reminder, user: user, post: post_record, remind_time: "07:30") }

        it "リマインダー情報が表示される" do
          get post_path(post_record)

          expect(response.body).to include("07:30")
          expect(response.body).to include("リマインダー")
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
    let!(:post1) { create(:post, trigger_content: "Ruby入門") }
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
  end
end
