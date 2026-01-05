# app/models/comment_bookmark.rb
# YouTubeコメントのブックマーク
class CommentBookmark < ApplicationRecord
  belongs_to :user
  belongs_to :youtube_comment

  validates :user_id, uniqueness: { scope: :youtube_comment_id, message: "既にブックマーク済みです" }

  scope :recent, -> { order(created_at: :desc) }
end
