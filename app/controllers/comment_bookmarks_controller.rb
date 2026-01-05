# app/controllers/comment_bookmarks_controller.rb
class CommentBookmarksController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_youtube_comment, only: [:create, :destroy]

  # ブックマーク追加
  def create
    @bookmark = current_user.comment_bookmarks.find_or_initialize_by(youtube_comment: @youtube_comment)

    if @bookmark.persisted?
      respond_to do |format|
        format.json { render json: { success: true, bookmarked: true, message: "既にブックマーク済みです" } }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@youtube_comment, :bookmark), partial: "comment_bookmarks/button", locals: { youtube_comment: @youtube_comment, bookmarked: true }) }
      end
      return
    end

    if @bookmark.save
      respond_to do |format|
        format.json { render json: { success: true, bookmarked: true } }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@youtube_comment, :bookmark), partial: "comment_bookmarks/button", locals: { youtube_comment: @youtube_comment, bookmarked: true }) }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, error: @bookmark.errors.full_messages.join(", ") }, status: :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  # ブックマーク解除
  def destroy
    @bookmark = current_user.comment_bookmarks.find_by(youtube_comment: @youtube_comment)

    if @bookmark&.destroy
      respond_to do |format|
        format.json { render json: { success: true, bookmarked: false } }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@youtube_comment, :bookmark), partial: "comment_bookmarks/button", locals: { youtube_comment: @youtube_comment, bookmarked: false }) }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, error: "ブックマークが見つかりません" }, status: :not_found }
        format.turbo_stream { head :not_found }
      end
    end
  end

  private

  def set_youtube_comment
    @youtube_comment = YoutubeComment.find(params[:youtube_comment_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { success: false, error: "コメントが見つかりません" }, status: :not_found }
      format.turbo_stream { head :not_found }
    end
  end
end
