# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :autocomplete, :youtube_search, :track_recommendation_click ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :track_recommendation_click ]
  before_action :check_owner, only: [ :edit, :update, :destroy ]

  def index
    @q = Post.ransack(params[:q])
    base_scope = @q.result(distinct: true).includes(:user, :achievements, :cheers, :comments, :post_entries)

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

    # ===== タイプ別フィルター =====
    if params[:type].present?
      @current_type = params[:type]
      @posts = filter_by_entry_type(base_scope, @current_type).page(params[:page]).per(20)
      @section_display = false
    # ===== その他フィルター使用時は従来の単一リスト表示 =====
    elsif using_filters?
      @posts = base_scope.recent.page(params[:page]).per(20)
      @section_display = false
    else
      # ===== セクション表示（エントリータイプ別） =====
      @section_display = true

      # 📝 メモ（最新6件）
      @posts_with_memos = Post.joins(:post_entries)
                              .where(post_entries: { entry_type: :key_point })
                              .includes(:user, :post_entries)
                              .order("post_entries.created_at DESC")
                              .distinct
                              .limit(6)

      # 💬 引用（最新6件）
      @posts_with_quotes = Post.joins(:post_entries)
                               .where(post_entries: { entry_type: :quote })
                               .includes(:user, :post_entries)
                               .order("post_entries.created_at DESC")
                               .distinct
                               .limit(6)

      # 🎯 アクション（最新6件）
      @posts_with_actions = Post.joins(:post_entries)
                                .where(post_entries: { entry_type: :action })
                                .includes(:user, :post_entries)
                                .order("post_entries.created_at DESC")
                                .distinct
                                .limit(6)

      # 📰 ブログ（公開済み、最新6件）
      @posts_with_blogs = Post.joins(:post_entries)
                              .where(post_entries: { entry_type: :blog })
                              .where.not(post_entries: { published_at: nil })
                              .includes(:user, :post_entries)
                              .order("post_entries.published_at DESC")
                              .distinct
                              .limit(6)

      # 🕐 最近の投稿（全て、最新12件）
      @posts_recent = base_scope.recent.limit(12)
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

  # フィルター（検索、達成状況、期日）が使用されているか
  def using_filters?
    params[:q].present? && params.dig(:q, :action_plan_or_youtube_title_or_youtube_channel_name_cont).present? ||
      params[:achievement].present? ||
      params[:deadline].present?
  end

  # エントリータイプでフィルター
  def filter_by_entry_type(scope, type)
    case type
    when "memo"
      scope.joins(:post_entries)
           .where(post_entries: { entry_type: :key_point })
           .distinct
           .order("post_entries.created_at DESC")
    when "quote"
      scope.joins(:post_entries)
           .where(post_entries: { entry_type: :quote })
           .distinct
           .order("post_entries.created_at DESC")
    when "action"
      scope.joins(:post_entries)
           .where(post_entries: { entry_type: :action })
           .distinct
           .order("post_entries.created_at DESC")
    when "blog"
      scope.joins(:post_entries)
           .where(post_entries: { entry_type: :blog })
           .where.not(post_entries: { published_at: nil })
           .distinct
           .order("post_entries.published_at DESC")
    else
      scope.recent
    end
  end
end
