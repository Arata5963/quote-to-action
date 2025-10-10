# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :check_owner, only: [:edit, :update, :destroy]

  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:user, :achievements, :likes, :comments)
    
    # ===== タブ絞り込み =====
    if params[:tab] == 'mine' && user_signed_in?
      @posts = @posts.where(user: current_user)
    end
    
    # ===== カテゴリ絞り込み =====
    if params[:category].present? && Post.categories.key?(params[:category])
      @posts = @posts.where(category: params[:category])
    end
    
    @posts = @posts.recent.page(params[:page]).per(20)
  end

  def show
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
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end

  def check_owner
    unless @post.user == current_user
      redirect_to @post, alert: "他のユーザーの投稿は編集・削除できません"
    end
  end

  def post_params
    params.require(:post).permit(:trigger_content, :action_plan, :image, :category)
  end
end