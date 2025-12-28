require 'rails_helper'

RSpec.describe FavoriteVideo, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    subject { build(:favorite_video) }

    it { should validate_presence_of(:youtube_url) }
    it { should validate_presence_of(:position) }

    describe "youtube_url format" do
      it "有効なYouTube URL（youtube.com）を受け入れる" do
        video = build(:favorite_video, youtube_url: "https://www.youtube.com/watch?v=abc123")
        expect(video).to be_valid
      end

      it "有効なYouTube URL（youtu.be）を受け入れる" do
        video = build(:favorite_video, youtube_url: "https://youtu.be/abc123")
        expect(video).to be_valid
      end

      it "無効なURLを拒否する" do
        video = build(:favorite_video, youtube_url: "https://example.com/video")
        expect(video).not_to be_valid
        expect(video.errors[:youtube_url]).to include("は有効なYouTube URLを入力してください")
      end
    end

    describe "position" do
      it "1〜3の範囲で有効" do
        (1..3).each do |pos|
          video = build(:favorite_video, position: pos)
          expect(video).to be_valid
        end
      end

      it "0は無効" do
        video = build(:favorite_video, position: 0)
        expect(video).not_to be_valid
      end

      it "4は無効" do
        video = build(:favorite_video, position: 4)
        expect(video).not_to be_valid
      end

      it "同じユーザーで同じpositionは無効" do
        user = create(:user)
        create(:favorite_video, user: user, position: 1)
        duplicate = build(:favorite_video, user: user, position: 1)
        expect(duplicate).not_to be_valid
      end
    end

    describe "max_videos_per_user" do
      it "4件目の登録は無効" do
        user = create(:user)
        create(:favorite_video, user: user, position: 1)
        create(:favorite_video, user: user, position: 2)
        create(:favorite_video, user: user, position: 3)

        # positionが重複しないように別の値を設定
        fourth = build(:favorite_video, user: user, position: 1)
        expect(fourth).not_to be_valid
        expect(fourth.errors[:base]).to include("すきな動画は最大3件までです")
      end
    end
  end

  describe "#youtube_video_id" do
    it "youtube.com形式からvideo_idを抽出する" do
      video = build(:favorite_video, youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      expect(video.youtube_video_id).to eq("dQw4w9WgXcQ")
    end

    it "youtu.be形式からvideo_idを抽出する" do
      video = build(:favorite_video, youtube_url: "https://youtu.be/dQw4w9WgXcQ")
      expect(video.youtube_video_id).to eq("dQw4w9WgXcQ")
    end

    it "URLがnilの場合はnilを返す" do
      video = build(:favorite_video)
      video.youtube_url = nil
      expect(video.youtube_video_id).to be_nil
    end
  end

  describe "#youtube_thumbnail_url" do
    it "サムネイルURLを生成する" do
      video = build(:favorite_video, youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      expect(video.youtube_thumbnail_url).to eq("https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg")
    end

    it "サイズを指定できる" do
      video = build(:favorite_video, youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      expect(video.youtube_thumbnail_url(size: :hqdefault)).to eq("https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
    end
  end
end
