# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  # Deviseの認証必須（ログインユーザーのみアクセス可能）
  before_action :authenticate_user!
  # 共通処理：該当PostをセットしてUserの所有権チェック
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]

  def index
    # ログインユーザーの投稿を新しい順で取得
    @posts = current_user.posts.recent
  end

  def show
    # set_postで@postは設定済み
  end

  def new
    # 新規投稿オブジェクトを作成（ログインユーザーに関連付け）
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      # i18n対応：config/locales/ja.ymlで管理
      redirect_to @post, notice: t("posts.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # set_postで@postは設定済み
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: t("posts.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: t("posts.destroy.success")
  end

  private

  def set_post
    # セキュリティ：ログインユーザーの投稿のみ取得
    @post = current_user.posts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end

  def post_params
    # Strong Parameters：許可するパラメータを制限
    params.require(:post).permit(:trigger_content, :action_plan)
  end
end
