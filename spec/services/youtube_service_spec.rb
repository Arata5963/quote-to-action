require 'rails_helper'

RSpec.describe YoutubeService, type: :service do
  describe '.fetch_video_info' do
    let(:video_id) { 'dQw4w9WgXcQ' }
    let(:youtube_url) { "https://www.youtube.com/watch?v=#{video_id}" }

    before do
      # YouTube APIサービスをモック
      youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
      allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)

      # APIレスポンスをモック
      video_snippet = double(
        title: 'Test Video Title',
        channel_title: 'Test Channel'
      )
      video_item = double(snippet: video_snippet)
      response = double(items: [ video_item ])
      allow(youtube_service).to receive(:list_videos).with('snippet', id: video_id).and_return(response)
    end

    context '有効なYouTube URLの場合' do
      it '動画情報を返す' do
        result = described_class.fetch_video_info(youtube_url)

        expect(result).to eq({
          title: 'Test Video Title',
          channel_name: 'Test Channel'
        })
      end
    end

    context 'youtu.be形式のURLの場合' do
      let(:short_url) { "https://youtu.be/#{video_id}" }

      it '動画情報を返す' do
        result = described_class.fetch_video_info(short_url)

        expect(result).to eq({
          title: 'Test Video Title',
          channel_name: 'Test Channel'
        })
      end
    end

    context 'パラメータ付きyoutu.be形式のURLの場合' do
      let(:short_url_with_params) { "https://youtu.be/#{video_id}?t=10" }

      it '動画情報を返す' do
        result = described_class.fetch_video_info(short_url_with_params)

        expect(result).to eq({
          title: 'Test Video Title',
          channel_name: 'Test Channel'
        })
      end
    end

    context 'URLがnilの場合' do
      it 'nilを返す' do
        result = described_class.fetch_video_info(nil)
        expect(result).to be_nil
      end
    end

    context 'URLが空の場合' do
      it 'nilを返す' do
        result = described_class.fetch_video_info('')
        expect(result).to be_nil
      end
    end

    context '無効なURLの場合' do
      it 'nilを返す' do
        result = described_class.fetch_video_info('https://example.com')
        expect(result).to be_nil
      end
    end

    context 'YouTube APIサービスが設定されていない場合' do
      before do
        allow(Rails.application.config).to receive(:youtube_service).and_return(nil)
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end
    end

    context '動画が存在しない場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        response = double(items: [])
        allow(youtube_service).to receive(:list_videos).and_return(response)
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end
    end

    context 'APIエラーが発生した場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        allow(youtube_service).to receive(:list_videos).and_raise(Google::Apis::ClientError.new('API Error'))
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end
    end
  end
end
