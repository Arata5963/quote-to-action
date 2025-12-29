# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :autocomplete ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :check_owner, only: [ :edit, :update, :destroy ]

  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:user, :achievements, :cheers, :comments)

    # ===== タブ絞り込み =====
    if params[:tab] == "mine" && user_signed_in?
      @posts = @posts.where(user: current_user)
    end

    # ===== 達成状況絞り込み =====
    case params[:achievement]
    when "achieved"
      @posts = @posts.where.not(achieved_at: nil)
    when "not_achieved"
      @posts = @posts.where(achieved_at: nil)
    end

    # ===== 期日絞り込み =====
    case params[:deadline]
    when "with_deadline"
      @posts = @posts.where.not(deadline: nil)
    when "overdue"
      @posts = @posts.where("deadline < ?", Date.current).where(achieved_at: nil)
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

  def autocomplete
    query = params[:q].to_s.strip

    if query.length >= 2
      @suggestions = Post
        .where(
          "action_plan ILIKE :q OR youtube_title ILIKE :q OR youtube_channel_name ILIKE :q",
          q: "%#{query}%"
        )
        .limit(10)
        .pluck(:action_plan, :youtube_title, :youtube_channel_name)
        .flatten
        .compact
        .uniq
        .select { |s| s.downcase.include?(query.downcase) }
        .first(10)
    else
      @suggestions = []
    end

    render layout: false
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
    params.require(:post).permit(:action_plan, :deadline, :youtube_url)
  end
end
