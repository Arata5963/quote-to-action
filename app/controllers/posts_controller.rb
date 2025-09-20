# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :check_owner, only: [:edit, :update, :destroy]

  def index
    # 全ユーザーの投稿を表示（パフォーマンス最適化でincludesを使用）
    @posts = Post.includes(:user, :achievements).recent
  end

  def show
    # 誰でも閲覧可能
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: t("posts.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # check_ownerで所有者チェック済み
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
    # 全ての投稿から検索（閲覧は誰でも可能）
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end

  def check_owner
    # 編集・削除は所有者のみ
    unless @post.user == current_user
      redirect_to @post, alert: "他のユーザーの投稿は編集・削除できません"
    end
  end

  def post_params
    params.require(:post).permit(:trigger_content, :action_plan, :image, :icon)
  end
end