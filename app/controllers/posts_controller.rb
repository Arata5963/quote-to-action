# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :autocomplete ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :check_owner, only: [ :edit, :update, :destroy ]

  def index
    @q = Post.ransack(params[:q])
    base_scope = @q.result(distinct: true).includes(:user, :achievements, :cheers, :comments)

    # ===== タブ絞り込み =====
    if params[:tab] == "mine" && user_signed_in?
      base_scope = base_scope.where(user: current_user)
    end

    # ===== 達成状況絞り込み =====
    case params[:achievement]
    when "achieved"
      base_scope = base_scope.where.not(achieved_at: nil)
    when "not_achieved"
      base_scope = base_scope.where(achieved_at: nil)
    end

    # ===== 期日絞り込み =====
    case params[:deadline]
    when "with_deadline"
      base_scope = base_scope.where.not(deadline: nil)
    when "overdue"
      base_scope = base_scope.where("deadline < ?", Date.current).where(achieved_at: nil)
    end

    # ===== グループ表示 or 通常表示 =====
    if using_filters?
      # フィルター使用時は従来の単一リスト表示
      @posts = base_scope.recent.page(params[:page]).per(20)
      @group_display = false
    else
      # デフォルト表示は期日グループ表示
      @posts_near = base_scope.not_achieved.deadline_near
      @posts_passed = base_scope.not_achieved.deadline_passed
      @posts_other = base_scope.not_achieved.deadline_other
      @posts_achieved = base_scope.achieved.recent.limit(10)
      @group_display = true
    end
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

  # フィルター（検索、タブ、達成状況、期日）が使用されているか
  def using_filters?
    params[:q].present? && params.dig(:q, :action_plan_or_youtube_title_or_youtube_channel_name_cont).present? ||
      params[:tab].present? ||
      params[:achievement].present? ||
      params[:deadline].present?
  end
end
