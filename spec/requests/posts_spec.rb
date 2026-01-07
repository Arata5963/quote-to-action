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
        post1 = create(:post, youtube_title: "タイトル1")
        post2 = create(:post, youtube_title: "タイトル2")
        post3 = create(:post, youtube_title: "タイトル3")

        get posts_path

        expect(response.body).to include("タイトル1")
        expect(response.body).to include("タイトル2")
        expect(response.body).to include("タイトル3")
      end

      it "フィルター使用時は新しい順に表示される" do
        old_post = create(:post, youtube_title: "古い投稿タイトル", created_at: 2.days.ago)
        new_post = create(:post, youtube_title: "新しい投稿タイトル", created_at: 1.day.ago)

        # フィルター使用で通常表示モードに
        get posts_path, params: { achievement: "not_achieved" }

        # 新しい投稿が先に表示される（HTML内の出現順）
        old_pos = response.body.index("古い投稿タイトル")
        new_pos = response.body.index("新しい投稿タイトル")

        expect(new_pos).to be < old_pos
      end
    end

    context "カード表示" do
      it "投稿がグリッドレイアウトで表示される" do
        create(:post, youtube_title: "タイトルA")
        create(:post, youtube_title: "タイトルB")

        get posts_path

        expect(response.body).to include("タイトルA")
        expect(response.body).to include("タイトルB")
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
        21.times { |i| create(:post, youtube_title: "テスト投稿#{i}") }

        # フィルター使用で通常表示モード（ページネーション有効）
        get posts_path, params: { achievement: "not_achieved" }

        # 20件分表示される（各投稿のタイトルがカード内に含まれる）
        expect(response.body.scan(/テスト投稿\d+/).uniq.size).to eq(20)
      end

      it "2ページ目が存在する" do
        # 21件の投稿を作成
        21.times { |i| create(:post, youtube_title: "テスト投稿#{i}") }

        # フィルター使用で通常表示モード
        get posts_path, params: { achievement: "not_achieved", page: 2 }

        expect(response).to have_http_status(200)
        # 2ページ目には1件だけ表示される
        expect(response.body.scan(/テスト投稿\d+/).uniq.size).to eq(1)
      end
    end

    context "投稿一覧表示" do
      let!(:post1) { create(:post, youtube_title: "テスト投稿A") }
      let!(:post2) { create(:post, youtube_title: "テスト投稿B") }

      it "すべての投稿が時系列で表示される" do
        get posts_path

        expect(response).to have_http_status(200)
        expect(response.body).to include("テスト投稿A")
        expect(response.body).to include("テスト投稿B")
      end
    end

    context "全投稿表示" do
      it "全ての投稿が表示される" do
        create(:post, youtube_title: "動画タイトル1")
        create(:post, youtube_title: "動画タイトル2")

        get posts_path

        expect(response).to have_http_status(200)
        expect(response.body).to include("動画タイトル1")
        expect(response.body).to include("動画タイトル2")
      end
    end

    context "Ransack検索" do
      let!(:post1) { create(:post, youtube_title: "Rubyプログラミング講座") }
      let!(:post2) { create(:post, youtube_title: "Python入門講座") }

      it "youtube_titleで検索できる" do
        get posts_path, params: { q: { youtube_title_cont: "Ruby" } }

        expect(response).to have_http_status(200)
        expect(response.body).to include("Rubyプログラミング講座")
        expect(response.body).not_to include("Python入門講座")
      end
    end
  end

  # ====================
  # GET /posts/:id (詳細表示)
  # ====================
  describe "GET /posts/:id" do
    let(:user) { create(:user) }
    let(:post_record) { create(:post, youtube_title: "テスト動画タイトル") }

    context "未ログインの場合" do
      it "投稿の詳細が表示される（公開ページ）" do
        get post_path(post_record)

        expect(response).to have_http_status(200)
        expect(response.body).to include("テスト動画タイトル")
      end
    end

    context "投稿が存在する場合" do
      it "投稿の詳細が表示される" do
        get post_path(post_record)

        expect(response).to have_http_status(200)
        expect(response.body).to include("テスト動画タイトル")
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
        expect(response.body).to include("動画を記録")
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
    let(:post_record) { create(:post) }

    context "エントリー所有者の場合" do
      before do
        create(:post_entry, post: post_record, user: user)
        sign_in user
      end

      it "編集フォームが表示される" do
        get edit_post_path(post_record)

        expect(response).to have_http_status(200)
        expect(response.body).to include("動画を編集")
      end
    end

    context "エントリー所有者でない場合" do
      before do
        create(:post_entry, post: post_record, user: user)
        sign_in other_user
      end

      it "詳細ページにリダイレクトされる" do
        get edit_post_path(post_record)

        expect(response).to redirect_to(post_path(post_record))
        follow_redirect!
        expect(response.body).to include("エントリーがありません")
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
    let(:post_record) { create(:post, action_plan: "元のアクション") }

    context "エントリー所有者の場合" do
      before do
        create(:post_entry, post: post_record, user: user)
        sign_in user
      end

      context "有効なパラメータの場合" do
        # Note: PATCHではyoutube_urlのみ更新可能（シンプル化によりaction_planは非推奨）
        it "詳細ページにリダイレクトされる" do
          patch post_path(post_record), params: { post: { youtube_url: post_record.youtube_url } }

          expect(response).to redirect_to(post_path(post_record))
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
          expect(response.body).to include("動画を編集")
        end
      end
    end

    context "エントリー所有者でない場合" do
      before do
        create(:post_entry, post: post_record, user: user)
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
        expect(response.body).to include("エントリーがありません")
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
    let!(:post_record) { create(:post) }

    context "エントリー所有者の場合" do
      before do
        create(:post_entry, post: post_record, user: user)
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
        expect(response.body).to include("エントリーを削除しました")
      end
    end

    context "エントリー所有者でない場合" do
      before do
        create(:post_entry, post: post_record, user: user)
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
        expect(response.body).to include("エントリーがありません")
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
    let!(:post1) { create(:post, youtube_title: "Ruby入門講座") }
    let!(:post2) { create(:post, youtube_title: "Rubyで自動化入門") }

    it "検索候補を返す" do
      get autocomplete_posts_path, params: { q: "Ruby" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ruby入門講座")
      expect(response.body).to include("Rubyで自動化入門")
    end

    it "2文字未満は空を返す" do
      get autocomplete_posts_path, params: { q: "R" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Ruby")
    end

    context "チャンネル名での検索" do
      let!(:post_with_youtube) do
        create(:post,
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
