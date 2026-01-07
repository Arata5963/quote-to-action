# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :autocomplete, :youtube_search, :track_recommendation_click, :search_for_comparison, :quotes_showcase, :find_or_create, :youtube_comments, :discover_comments ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :track_recommendation_click, :summarize, :quotes_showcase, :suggest_quotes, :add_quotes, :youtube_comments, :discover_comments ]
  before_action :check_has_entries, only: [ :edit, :update, :destroy ]

  def index
    @q = Post.ransack(params[:q])
    base_scope = @q.result(distinct: true).includes(:achievements, :cheers, :comments, :post_entries)

    # ===== ユーザー絞り込み =====
    if params[:user_id].present?
      @filter_user = User.find_by(id: params[:user_id])
      if @filter_user
        # そのユーザーがエントリーを持つ投稿のみ表示
        post_ids_with_entries = PostEntry.where(user_id: params[:user_id]).select(:post_id).distinct
        base_scope = base_scope.where(id: post_ids_with_entries)
      end
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
    @post = Post.new(youtube_url: params[:youtube_url])
    @entry = PostEntry.new(entry_type: :action) # デフォルトは行動
  end

  # YouTube URLから投稿を検索または作成してリダイレクト
  def find_or_create
    youtube_url = params[:youtube_url]

    if youtube_url.blank?
      render json: { success: false, error: "URLが必要です" }, status: :unprocessable_entity
      return
    end

    is_new_post = !Post.exists?(youtube_video_id: Post.extract_video_id(youtube_url))
    @post = Post.find_or_create_by_video(youtube_url: youtube_url)

    if @post
      # 新規作成時はAI要約を自動生成（ジョブキュー未設定でもエラーにしない）
      if is_new_post && @post.ai_summary.blank?
        begin
          GenerateSummaryJob.perform_later(@post.id)
        rescue StandardError => e
          Rails.logger.warn("Failed to enqueue GenerateSummaryJob: #{e.message}")
        end
      end
      render json: { success: true, post_id: @post.id, url: post_path(@post) }
    else
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity
    end
  end

  def create
    youtube_url = post_params[:youtube_url]

    # 1. 動画IDでPostを検索または作成（ユーザー不問）
    @post = Post.find_or_create_by_video(youtube_url: youtube_url)

    unless @post
      @post = Post.new(youtube_url: youtube_url)
      unless @post.save
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { success: false, error: @post.errors.full_messages }, status: :unprocessable_entity }
        end
        return
      end
    end

    # サイレント投稿（クイズ用）: PostのIDのみ返す
    if params[:silent]
      render json: { success: true, id: @post.id, post_id: @post.id }
      return
    end

    # 2. 複数エントリーを作成（user_idとanonymousを設定）
    entries_params = params[:entries] || {}
    blog_params = params[:blog_entry]
    satisfaction = params[:satisfaction_rating].presence
    anonymous = params[:anonymous] == "1"
    created_count = 0
    blog_published = false

    ActiveRecord::Base.transaction do
      # 要約エントリー
      (entries_params[:keyPoint] || {}).each_value do |entry_data|
        next if entry_data[:content].blank?
        @post.post_entries.create!(
          user: current_user,
          anonymous: anonymous,
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
          user: current_user,
          anonymous: anonymous,
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
          user: current_user,
          anonymous: anonymous,
          entry_type: :action,
          content: entry_data[:content],
          deadline: entry_data[:deadline].presence,
          satisfaction_rating: satisfaction
        )
        # action_plan互換性のため、最初のアクションをPostにも保存
        if @post.action_plan.blank?
          @post.update(action_plan: entry.content)
        end
        created_count += 1
        satisfaction = nil
      end

      # ブログエントリー（ブログモードの場合）
      if blog_params.present? && (blog_params[:title].present? || blog_params[:content].present?)
        @post.post_entries.create!(
          user: current_user,
          anonymous: anonymous,
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
          user: current_user,
          anonymous: anonymous,
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

    # AI要約を自動生成（まだない場合）
    if @post.ai_summary.blank?
      GenerateSummaryJob.perform_later(@post.id)
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
    # 自分のエントリーのみ削除
    @post.entries_by_user(current_user).destroy_all

    # 他にエントリーがなければ投稿自体も削除
    if @post.post_entries.empty?
      @post.destroy
    end

    redirect_to posts_path, notice: "エントリーを削除しました"
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

  # AI学習ガイドを生成
  def summarize
    result = GeminiService.summarize_video(@post)

    respond_to do |format|
      if result[:success]
        @summary = result[:summary]
        # 要約をDBに保存
        @post.update(ai_summary: @summary)
        format.turbo_stream
        format.json { render json: { success: true, summary: @summary } }
      else
        @error = result[:error]
        format.turbo_stream { render :summarize_error }
        format.json { render json: { success: false, error: @error }, status: :unprocessable_entity }
      end
    end
  end

  # 引用ショーケースページ
  def quotes_showcase
    @quotes = @post.post_entries.where(entry_type: :quote).recent.includes(:user)
    render layout: false
  end

  # YouTubeコメントを取得
  def youtube_comments
    @comments = YoutubeService.fetch_top_comments(@post.youtube_video_id, max_results: 20)

    respond_to do |format|
      format.json { render json: { success: true, comments: @comments } }
      format.turbo_stream
      format.html { render layout: false }
    end
  end

  # YouTubeコメントを取得・保存（ブックマーク用）
  def discover_comments
    # 既に保存済みコメントがある場合はそれを返す
    existing_comments = @post.youtube_comments.by_like_count
    if existing_comments.any?
      @youtube_comments = existing_comments
      respond_to do |format|
        format.json { render json: { success: true, comments: format_youtube_comments(@youtube_comments), cached: true } }
        format.turbo_stream
        format.html { render layout: false }
      end
      return
    end

    # YouTubeからコメントを取得
    raw_comments = YoutubeService.fetch_top_comments(@post.youtube_video_id, max_results: 50)

    if raw_comments.blank?
      respond_to do |format|
        format.json { render json: { success: false, error: "コメントを取得できませんでした" }, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("youtube-comments-container", partial: "posts/no_comments") }
      end
      return
    end

    # コメントを保存（カテゴリなし）
    save_comments_without_category(raw_comments)
    @youtube_comments = @post.youtube_comments.reload.by_like_count

    respond_to do |format|
      format.json { render json: { success: true, comments: format_youtube_comments(@youtube_comments) } }
      format.turbo_stream
    end
  end

  # AIによる引用候補を提案
  def suggest_quotes
    result = GeminiService.suggest_quotes(
      video_id: @post.youtube_video_id,
      title: @post.youtube_title
    )

    render json: result
  end

  # 引用を追加
  def add_quotes
    quotes = params[:quotes] || []

    if quotes.empty?
      render json: { success: false, error: "引用が選択されていません" }
      return
    end

    created_count = 0
    quotes.each do |content|
      next if content.blank?

      # 同じ内容の引用が既にあるかチェック（正規化して比較）
      normalized = content.strip.gsub(/\s+/, ' ')
      existing = @post.post_entries.where(entry_type: :quote).find do |q|
        q.content.strip.gsub(/\s+/, ' ') == normalized
      end

      if existing
        # 既存の引用がある場合はスキップ（将来的には「共感」機能に）
        next
      end

      @post.post_entries.create!(
        user: current_user,
        entry_type: :quote,
        content: content.strip,
        anonymous: false
      )
      created_count += 1
    end

    render json: { success: true, created_count: created_count }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: e.message }
  end

  # AIでエントリー内容を生成
  def generate_entry
    video_id = params[:video_id]
    entry_type = params[:entry_type]
    title = params[:title]

    if video_id.blank?
      render json: { success: false, error: "動画IDがありません" }, status: :unprocessable_entity
      return
    end

    result = GeminiService.generate_entry(
      video_id: video_id,
      entry_type: entry_type,
      title: title
    )

    if result[:success]
      render json: { success: true, content: result[:content] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
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

  def check_has_entries
    unless @post.has_entries_by?(current_user)
      redirect_to @post, alert: "この動画にはあなたのエントリーがありません"
    end
  end

  def post_params
    params.require(:post).permit(:action_plan, :youtube_url)
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

  # YouTubeコメントをカテゴリなしで保存
  def save_comments_without_category(comments)
    comments.each do |comment|
      @post.youtube_comments.find_or_create_by(youtube_comment_id: comment[:comment_id]) do |yc|
        yc.author_name = comment[:author]
        yc.author_image_url = comment[:author_image]
        yc.author_channel_url = comment[:author_channel_url]
        yc.content = comment[:text]
        yc.like_count = comment[:like_count] || 0
        yc.youtube_published_at = comment[:published_at]
      end
    end
  end

  # 分類済みYouTubeコメントを保存
  def save_categorized_comments(comments)
    comments.each do |comment|
      @post.youtube_comments.find_or_create_by(youtube_comment_id: comment[:comment_id]) do |yc|
        yc.author_name = comment[:author]
        yc.author_image_url = comment[:author_image]
        yc.author_channel_url = comment[:author_channel_url]
        yc.content = comment[:text]
        yc.like_count = comment[:like_count] || 0
        yc.category = comment[:category]
        yc.youtube_published_at = comment[:published_at]
      end
    end
  end

  # YoutubeCommentをJSON形式にフォーマット
  def format_youtube_comments(comments)
    comments.map do |comment|
      {
        id: comment.id,
        comment_id: comment.youtube_comment_id,
        author: comment.author_name,
        author_image: comment.author_image_url,
        author_channel_url: comment.author_channel_url,
        text: comment.content,
        like_count: comment.like_count,
        category: comment.category,
        category_label: comment.category_label,
        category_emoji: comment.category_emoji,
        youtube_url: comment.youtube_url,
        bookmarked: user_signed_in? ? comment.bookmarked_by?(current_user) : false
      }
    end
  end
end
