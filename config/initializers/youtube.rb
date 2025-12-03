# frozen_string_literal: true

# YouTube Data API v3の初期化設定
require "google/apis/youtube_v3"

Rails.application.config.youtube_service = if ENV["YOUTUBE_API_KEY"].present?
  Google::Apis::YoutubeV3::YouTubeService.new.tap do |youtube|
    youtube.key = ENV["YOUTUBE_API_KEY"]
  end
end
