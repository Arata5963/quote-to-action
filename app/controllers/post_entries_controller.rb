# app/controllers/post_entries_controller.rb
class PostEntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!, except: [:show]
  before_action :set_post
  before_action :set_entry, only: [:show, :edit, :update, :destroy, :achieve, :publish, :unpublish]
  before_action :check_entry_owner, only: [:edit, :update, :destroy, :achieve, :publish, :unpublish]
  before_action :check_blog_access, only: [:show]

  # ブログ詳細表示
  def show
    unless @entry.blog?
      redirect_to @post
      return
    end
  end

  # ブログ新規作成画面
  def new_blog
    @entry = @post.post_entries.build(entry_type: :blog)
  end

  # 編集画面
  def edit
    # ブログは専用ページ、その他はインライン編集のためリダイレクト不要
  end

  def create
    @entry = @post.post_entries.build(entry_params)
    @entry.user = current_user
    @entry.anonymous = params[:post_entry][:anonymous] == "1"

    # ブログの場合は公開/下書きを判定
    if @entry.blog?
      @entry.published_at = Time.current if params[:publish].present?
    end

    if @entry.save
      # actionタイプの場合はPostにも反映（互換性のため）
      if @entry.action?
        @post.update(action_plan: @entry.content)
      end

      if @entry.blog?
        message = @entry.published? ? "ブログを公開しました" : "下書きを保存しました"
        redirect_to post_post_entry_path(@post, @entry), notice: message
      else
        redirect_to @post, notice: success_message(@entry)
      end
    else
      if @entry.blog?
        render :new_blog, status: :unprocessable_entity
      else
        redirect_to @post, alert: "追記に失敗しました: #{@entry.errors.full_messages.join(', ')}"
      end
    end
  end

  def update
    # ブログの場合は公開/下書きを判定
    if @entry.blog?
      if params[:publish].present? && @entry.draft?
        entry_params_with_publish = entry_params.merge(published_at: Time.current)
        @entry.assign_attributes(entry_params_with_publish)
      else
        @entry.assign_attributes(entry_params)
      end
    else
      @entry.assign_attributes(entry_params)
    end

    if @entry.save
      if @entry.blog?
        message = params[:publish].present? ? "ブログを公開しました" : "ブログを更新しました"
        redirect_to post_post_entry_path(@post, @entry), notice: message
      else
        redirect_to @post, notice: update_message(@entry)
      end
    else
      if @entry.blog?
        render :edit, status: :unprocessable_entity
      else
        redirect_to @post, alert: "更新に失敗しました"
      end
    end
  end

  def destroy
    @entry.destroy
    redirect_to @post, notice: "削除しました"
  end

  # ブログを公開
  def publish
    if @entry.publish!
      redirect_to post_post_entry_path(@post, @entry), notice: "ブログを公開しました"
    else
      redirect_to post_post_entry_path(@post, @entry), alert: "公開に失敗しました"
    end
  end

  # ブログを非公開（下書きに戻す）
  def unpublish
    if @entry.unpublish!
      redirect_to post_post_entry_path(@post, @entry), notice: "下書きに戻しました"
    else
      redirect_to post_post_entry_path(@post, @entry), alert: "操作に失敗しました"
    end
  end

  def bulk_create
    entries_params = params[:entries] || {}
    anonymous = params[:anonymous] == "1"
    created_count = 0

    ActiveRecord::Base.transaction do
      # 要約
      (entries_params[:keyPoint] || {}).each_value do |entry_data|
        next if entry_data[:content].blank?
        @post.post_entries.create!(
          user: current_user,
          anonymous: anonymous,
          entry_type: :key_point,
          content: entry_data[:content]
        )
        created_count += 1
      end

      # 引用
      (entries_params[:quote] || {}).each_value do |entry_data|
        next if entry_data[:content].blank?
        @post.post_entries.create!(
          user: current_user,
          anonymous: anonymous,
          entry_type: :quote,
          content: entry_data[:content]
        )
        created_count += 1
      end

      # アクション
      (entries_params[:action] || {}).each_value do |entry_data|
        next if entry_data[:content].blank?
        entry = @post.post_entries.create!(
          user: current_user,
          anonymous: anonymous,
          entry_type: :action,
          content: entry_data[:content],
          deadline: entry_data[:deadline].presence
        )
        # 最初のactionをPostにも反映（互換性のため）
        if @post.action_plan.blank?
          @post.update(action_plan: entry.content)
        end
        created_count += 1
      end
    end

    if created_count > 0
      redirect_to @post, notice: "#{created_count}件のアウトプットを保存しました"
    else
      redirect_to @post, alert: "保存するアウトプットがありません"
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @post, alert: "保存に失敗しました: #{e.message}"
  end

  def achieve
    if @entry.achieve!
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@entry),
            partial: "post_entries/task_card",
            locals: { task: @entry }
          )
        end
        format.html { redirect_to @post, notice: @entry.achieved? ? "達成おめでとうございます！" : "未達成に戻しました" }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to @post, alert: "達成処理に失敗しました" }
      end
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_entry
    @entry = @post.post_entries.find(params[:id])
  end

  def check_entry_owner
    unless @entry.user == current_user
      redirect_to @post, alert: "他のユーザーのエントリーは編集・削除できません"
    end
  end

  # ブログ閲覧権限チェック（本人は下書きも見れる、他人は公開済みのみ）
  def check_blog_access
    return if @entry.user == current_user
    return if @entry.published?

    redirect_to @post, alert: "このブログは公開されていません"
  end

  def entry_params
    params.require(:post_entry).permit(
      :entry_type, :content, :deadline, :satisfaction_rating, :title,
      :recommendation_level, :target_audience, :recommendation_point
    )
  end

  def success_message(entry)
    case entry.entry_type
    when "key_point" then "メモを追記しました"
    when "action" then "アクションを追記しました"
    when "quote" then "引用を追記しました"
    when "blog" then "ブログを保存しました"
    when "recommendation" then "布教しました！"
    else "追記しました"
    end
  end

  def update_message(entry)
    case entry.entry_type
    when "key_point" then "メモを更新しました"
    when "action" then "アクションを更新しました"
    when "quote" then "引用を更新しました"
    when "blog" then "ブログを更新しました"
    when "recommendation" then "布教を更新しました"
    else "更新しました"
    end
  end
end
