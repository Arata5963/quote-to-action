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

      it "フィルター使用時は新しい順に表示される" do
        old_post = create(:post, action_plan: "古いアクション", created_at: 2.days.ago)
        new_post = create(:post, action_plan: "新しいアクション", created_at: 1.day.ago)

        # フィルター使用で通常表示モードに
        get posts_path, params: { achievement: "not_achieved" }

        # 新しい投稿が先に表示される（HTML内の出現順）
        old_pos = response.body.index("古いアクション")
        new_pos = response.body.index("新しいアクション")

        expect(new_pos).to be < old_pos
      end
    end

    context "カード表示" do
      it "投稿がグリッドレイアウトで表示される" do
        create(:post, action_plan: "アクション1", deadline: Date.current + 2.days)
        create(:post, action_plan: "アクション2", deadline: Date.current - 1.day)

        get posts_path

        expect(response.body).to include("アクション1")
        expect(response.body).to include("アクション2")
      end

      it "YouTubeサムネイルが表示される" do
        create(:post, youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")

        get posts_path

        expect(response.body).to include("img.youtube.com")
      end
    end

    context "ページネーション（フィルター使用時）" do
      it "1ページ目に20件まで表示される" do
        # 21件の投稿を作成
        21.times { |i| create(:post, action_plan: "アクション#{i}") }

        # フィルター使用で通常表示モード（ページネーション有効）
        get posts_path, params: { achievement: "not_achieved" }

        # 20件分表示される
        expect(response.body.scan(/アクション\d+/).size).to eq(20)
      end

      it "2ページ目が存在する" do
        # 21件の投稿を作成
        21.times { |i| create(:post, action_plan: "アクション#{i}") }

        # フィルター使用で通常表示モード
        get posts_path, params: { achievement: "not_achieved", page: 2 }

        expect(response).to have_http_status(200)
        # 2ページ目には1件だけ表示される
        expect(response.body.scan(/アクション\d+/).size).to eq(1)
      end
    end

    context "達成状況絞り込み" do
      let!(:achieved_post) { create(:post, action_plan: "達成済みアクション", achieved_at: Time.current) }
      let!(:not_achieved_post) { create(:post, action_plan: "未達成アクション", achieved_at: nil) }

      it "達成済みのみ表示できる" do
        get posts_path, params: { achievement: "achieved" }

        expect(response.body).to include("達成済みアクション")
        expect(response.body).not_to include("未達成アクション")
      end

      it "未達成のみ表示できる" do
        get posts_path, params: { achievement: "not_achieved" }

        expect(response.body).to include("未達成アクション")
        expect(response.body).not_to include("達成済みアクション")
      end

      it "無効な達成状況パラメータは無視される" do
        get posts_path, params: { achievement: "invalid" }

        expect(response).to have_http_status(200)
        expect(response.body).to include("達成済みアクション")
        expect(response.body).to include("未達成アクション")
      end
    end

    context "全投稿表示" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }

      it "全ての投稿が表示される" do
        my_post = create(:post, user: user, action_plan: "自分のアクション")
        others_post = create(:post, user: other_user, action_plan: "他人のアクション")

        get posts_path

        expect(response).to have_http_status(200)
        expect(response.body).to include("自分のアクション")
        expect(response.body).to include("他人のアクション")
      end
    end

    context "Ransack検索" do
      let!(:post1) { create(:post, action_plan: "Rubyプログラミング") }
      let!(:post2) { create(:post, action_plan: "Python入門") }

      it "action_planで検索できる" do
        get posts_path, params: { q: { action_plan_cont: "Ruby" } }

        expect(response).to have_http_status(200)
        expect(response.body).to include("Rubyプログラミング")
        expect(response.body).not_to include("Python入門")
      end
    end
  end

  # ====================
  # GET /posts/:id (詳細表示)
  # ====================
  describe "GET /posts/:id" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post, user: user, action_plan: "テストアクション") }

    context "未ログインの場合" do
      it "投稿の詳細が表示される（公開ページ）" do
        get post_path(post_record)

        expect(response).to have_http_status(200)
        expect(response.body).to include("テストアクション")
      end
    end

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
              youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
            },
            entries: {
              action: {
                "0" => {
                  content: "新しいアクションプラン",
                  deadline: (Date.current + 7.days).to_s
                }
              }
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
          expect(response.body).to include("アクション")
        end

        it "current_userの投稿として作成される" do
          post posts_path, params: valid_params

          expect(Post.last.user).to eq(user)
        end

        it "PostEntryも作成される" do
          expect {
            post posts_path, params: valid_params
          }.to change(PostEntry, :count).by(1)
        end

        it "複数のエントリーを作成できる" do
          multi_params = {
            post: {
              youtube_url: "https://www.youtube.com/watch?v=test123"
            },
            entries: {
              keyPoint: {
                "0" => { content: "ポイント1" },
                "1" => { content: "ポイント2" }
              },
              quote: {
                "0" => { content: "引用1" }
              },
              action: {
                "0" => { content: "アクション1", deadline: (Date.current + 7.days).to_s }
              }
            }
          }

          expect {
            post posts_path, params: multi_params
          }.to change(PostEntry, :count).by(4)
        end
      end

      context "エントリーなしでも投稿できる" do
        let(:no_entry_params) do
          {
            post: {
              youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
            }
          }
        end

        it "投稿は作成される" do
          expect {
            post posts_path, params: no_entry_params
          }.to change(Post, :count).by(1)
        end

        it "PostEntryは作成されない" do
          expect {
            post posts_path, params: no_entry_params
          }.not_to change(PostEntry, :count)
        end

        it "詳細ページにリダイレクトされる" do
          post posts_path, params: no_entry_params

          expect(response).to redirect_to(post_path(Post.last))
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
        expect(response.body).to include("更新する")
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
              youtube_url: "invalid-url" # 無効なURL
            }
          }
        end

        it "投稿が更新されない" do
          patch post_path(post_record), params: invalid_params

          post_record.reload
          expect(post_record.youtube_url).not_to eq("invalid-url")
        end

        it "編集フォームが再表示される" do
          patch post_path(post_record), params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("更新する")
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
        expect(response.body).to include("投稿を削除しました")
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
