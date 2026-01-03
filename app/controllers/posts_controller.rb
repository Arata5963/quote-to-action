# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :autocomplete, :youtube_search, :track_recommendation_click, :search_for_comparison ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :track_recommendation_click ]
  before_action :check_owner, only: [ :edit, :update, :destroy ]

  def index
    @q = Post.ransack(params[:q])
    base_scope = @q.result(distinct: true).includes(:user, :achievements, :cheers, :comments, :post_entries)

    # ===== ユーザー絞り込み =====
    if params[:user_id].present?
      @filter_user = User.find_by(id: params[:user_id])
      base_scope = base_scope.where(user_id: params[:user_id]) if @filter_user
    end

    # シンプルに時系列表示
    @posts = base_scope.recent.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.turbo_stream { render partial: "posts/posts_page", locals: { posts: @posts } }
    end
  end

  def show
  end

  def new
    @post = current_user.posts.build
    @entry = PostEntry.new(entry_type: :action) # デフォルトは行動
  end

  def create
    youtube_url = post_params[:youtube_url]

    # 1. 動画IDでPostを検索または作成
    @post = Post.find_or_initialize_by_video(
      user: current_user,
      youtube_url: youtube_url
    )

    unless @post
      @post = current_user.posts.build(youtube_url: youtube_url)
    end

    # 2. Postを保存（新規の場合）
    unless @post.persisted?
      unless @post.save
        render :new, status: :unprocessable_entity
        return
      end
    end

    # 3. 複数エントリーを作成
    entries_params = params[:entries] || {}
    blog_params = params[:blog_entry]
    satisfaction = params[:satisfaction_rating].presence
    created_count = 0
    blog_published = false

    ActiveRecord::Base.transaction do
      # 要約エントリー
      (entries_params[:keyPoint] || {}).each_value do |entry_data|
        next if entry_data[:content].blank?
        @post.post_entries.create!(
          entry_type: :key_point,
          content: entry_data[:content],
          satisfaction_rating: satisfaction
        )
        created_count += 1
        satisfaction = nil # 最初のエントリーにのみ満足度を設定
      end

      # 引用エントリー
      (entries_params[:quote] || {}).each_value do |entry_data|
        next if entry_data[:content].blank?
        @post.post_entries.create!(
          entry_type: :quote,
          content: entry_data[:content],
          satisfaction_rating: satisfaction
        )
        created_count += 1
        satisfaction = nil
      end

      # アクションエントリー
      (entries_params[:action] || {}).each_value do |entry_data|
        next if entry_data[:content].blank?
        entry = @post.post_entries.create!(
          entry_type: :action,
          content: entry_data[:content],
          deadline: entry_data[:deadline].presence,
          satisfaction_rating: satisfaction
        )
        # action_plan互換性のため、最初のアクションをPostにも保存
        if @post.action_plan.blank?
          @post.update(action_plan: entry.content, deadline: entry.deadline)
        end
        created_count += 1
        satisfaction = nil
      end

      # ブログエントリー（ブログモードの場合）
      if blog_params.present? && (blog_params[:title].present? || blog_params[:content].present?)
        blog_entry = @post.post_entries.create!(
          entry_type: :blog,
          title: blog_params[:title],
          content: blog_params[:content],
          published_at: blog_params[:publish].present? ? Time.current : nil
        )
        created_count += 1
        blog_published = blog_params[:publish].present?
      end

      # 布教エントリー
      recommendation_params = params[:recommendation]
      if recommendation_params.present? && recommendation_params[:level].present?
        @post.post_entries.create!(
          entry_type: :recommendation,
          recommendation_level: recommendation_params[:level].to_i,
          recommendation_point: recommendation_params[:point],
          target_audience: recommendation_params[:audience]
        )
        created_count += 1
      end

      # 比較
      comparisons_params = params[:comparisons] || {}
      comparisons_params.each_value do |comparison_data|
        next if comparison_data[:target_post_id].blank?
        @post.outgoing_comparisons.create!(
          target_post_id: comparison_data[:target_post_id].to_i,
          reason: comparison_data[:reason]
        )
        created_count += 1
      end
    end

    if created_count > 0
      # ブログが公開された場合は別メッセージ
      if blog_published
        redirect_to @post, notice: "ブログを公開しました"
      else
        redirect_to @post, notice: "#{created_count}件のアウトプットを記録しました"
      end
    else
      # エントリーなしでも投稿自体は作成済み
      redirect_to @post, notice: "動画を記録しました"
    end
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def edit
    @entry = @post.latest_entry || PostEntry.new(entry_type: :action)
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

  # YouTube動画を検索
  def youtube_search
    query = params[:q].to_s.strip

    if query.length >= 2
      @videos = YoutubeService.search_videos(query, max_results: 8)
    else
      @videos = []
    end

    respond_to do |format|
      format.json { render json: @videos }
      format.html { render layout: false }
    end
  end

  # 布教クリックを追跡（YouTubeリンククリック時）
  def track_recommendation_click
    # ログインユーザーのみ、布教がある場合のみ追跡
    if user_signed_in? && @post.has_recommendation?
      RecommendationClick.record_click(post: @post, user: current_user)
    end

    head :ok
  end

  # 比較用の投稿検索
  def search_for_comparison
    query = params[:q].to_s.strip

    if query.length >= 2
      posts = Post.where(
        "youtube_title ILIKE :q OR youtube_channel_name ILIKE :q",
        q: "%#{query}%"
      ).limit(10)

      results = posts.map do |post|
        {
          id: post.id,
          title: post.youtube_title || "タイトル不明",
          channel: post.youtube_channel_name || "チャンネル不明",
          thumbnail: post.youtube_thumbnail_url
        }
      end

      render json: results
    else
      render json: []
    end
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

  def entry_params
    params.require(:post_entry).permit(:entry_type, :content, :deadline, :satisfaction_rating)
  end

  def entry_success_message(entry)
    case entry.entry_type
    when "key_point" then "要約を記録しました"
    when "quote" then "引用を記録しました"
    when "action" then "アクションプランを設定しました"
    else t("posts.create.success")
    end
  end
end
