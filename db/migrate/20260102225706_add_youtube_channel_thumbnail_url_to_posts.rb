class AddYoutubeChannelThumbnailUrlToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_channel_thumbnail_url, :string
  end
end
