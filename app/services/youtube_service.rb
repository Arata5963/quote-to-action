# frozen_string_literal: true

# YouTube Data API v3を使用して動画情報を取得するサービスクラス
class YoutubeService
  class << self
    # YouTube URLから動画情報（タイトル・チャンネル名）を取得
    # @param youtube_url [String] YouTube動画のURL
    # @return [Hash, nil] { title:, channel_name: } または nil（取得失敗時）
    def fetch_video_info(youtube_url)
      video_id = extract_video_id(youtube_url)
      return nil if video_id.blank?

      fetch_from_api(video_id)
    rescue Google::Apis::ClientError => e
      Rails.logger.warn("YouTube API client error: #{e.message}")
      nil
    rescue Google::Apis::ServerError => e
      Rails.logger.error("YouTube API server error: #{e.message}")
      nil
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error("YouTube API authorization error: #{e.message}")
      nil
    end

    private

    # YouTube URLからvideo_idを抽出
    # @param url [String] YouTube URL
    # @return [String, nil] video_id または nil
    def extract_video_id(url)
      return nil if url.blank?

      if url.include?("youtube.com/watch")
        URI.parse(url).query&.split("&")
           &.find { |p| p.start_with?("v=") }
           &.delete_prefix("v=")
      elsif url.include?("youtu.be/")
        url.split("youtu.be/").last&.split("?")&.first
      end
    rescue URI::InvalidURIError
      nil
    end

    # YouTube Data API v3から動画情報を取得
    # @param video_id [String] YouTube動画ID
    # @return [Hash, nil] { title:, channel_name: } または nil
    def fetch_from_api(video_id)
      youtube = Rails.application.config.youtube_service
      return nil if youtube.nil?

      response = youtube.list_videos("snippet", id: video_id)
      return nil if response.items.blank?

      video = response.items.first
      {
        title: video.snippet.title,
        channel_name: video.snippet.channel_title
      }
    end
  end
end
