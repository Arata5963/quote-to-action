require 'rails_helper'

RSpec.describe Post, type: :model do
  describe "validations" do
    it { should validate_presence_of(:trigger_content) }
    it { should validate_presence_of(:action_plan) }
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:youtube_url) }
    it { should validate_length_of(:trigger_content).is_at_most(100) }
    it { should validate_length_of(:action_plan).is_at_most(100) }

    # YouTube URL検証
    it { should allow_value('https://www.youtube.com/watch?v=dQw4w9WgXcQ').for(:youtube_url) }
    it { should allow_value('https://youtu.be/dQw4w9WgXcQ').for(:youtube_url) }
    it { should_not allow_value('https://example.com').for(:youtube_url) }
    it { should_not allow_value('invalid-url').for(:youtube_url) }
  end
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:achievements) }
    it { should have_many(:comments) }
    it { should have_many(:likes) }
  end
  describe "#liked_by?" do
    let(:user) { create(:user) }
    let(:post) { create(:post) }

    context "いいねしている場合" do
      before { create(:like, post: post, user: user) }

      it "true を返す" do
        expect(post.liked_by?(user)).to be true
      end
    end

    context "いいねしていない場合" do
      it "false を返す" do
        expect(post.liked_by?(user)).to be false
      end
    end
  end
  describe ".recent" do
    it "新しい順に並ぶ" do
      old_post = create(:post, created_at: 3.days.ago)
      middle_post = create(:post, created_at: 1.day.ago)
      new_post = create(:post, created_at: Time.current)

      expect(Post.recent).to eq([ new_post, middle_post, old_post ])
    end
  end

  describe "#youtube_video_id" do
    context "youtube.com/watch形式のURL" do
      let(:post) { build(:post, youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ') }

      it "動画IDを抽出する" do
        expect(post.youtube_video_id).to eq('dQw4w9WgXcQ')
      end
    end

    context "youtu.be形式のURL" do
      let(:post) { build(:post, youtube_url: 'https://youtu.be/dQw4w9WgXcQ') }

      it "動画IDを抽出する" do
        expect(post.youtube_video_id).to eq('dQw4w9WgXcQ')
      end
    end

    context "パラメータ付きyoutu.be形式" do
      let(:post) { build(:post, youtube_url: 'https://youtu.be/dQw4w9WgXcQ?t=10') }

      it "動画IDのみを抽出する" do
        expect(post.youtube_video_id).to eq('dQw4w9WgXcQ')
      end
    end
  end

  describe "#youtube_thumbnail_url" do
    let(:post) { build(:post, youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ') }

    it "サムネイルURLを返す" do
      expect(post.youtube_thumbnail_url).to eq('https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg')
    end

    it "サイズを指定できる" do
      expect(post.youtube_thumbnail_url(size: :maxresdefault)).to eq('https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg')
    end
  end

  describe "#youtube_embed_url" do
    context "有効なYouTube URLの場合" do
      let(:post) { build(:post, youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ') }

      it "埋め込みURLを返す" do
        expect(post.youtube_embed_url).to eq('https://www.youtube.com/embed/dQw4w9WgXcQ')
      end
    end

    context "youtu.be形式のURLの場合" do
      let(:post) { build(:post, youtube_url: 'https://youtu.be/dQw4w9WgXcQ') }

      it "埋め込みURLを返す" do
        expect(post.youtube_embed_url).to eq('https://www.youtube.com/embed/dQw4w9WgXcQ')
      end
    end

    context "YouTube URLが空の場合" do
      let(:post) { build(:post) }

      before { allow(post).to receive(:youtube_video_id).and_return(nil) }

      it "nilを返す" do
        expect(post.youtube_embed_url).to be_nil
      end
    end
  end

  describe "#achieved?" do
    let(:post) { create(:post) }

    context "achieved_atが設定されている場合" do
      before { post.update(achieved_at: Time.current) }

      it "trueを返す" do
        expect(post.achieved?).to be true
      end
    end

    context "achieved_atが設定されていない場合" do
      it "falseを返す" do
        expect(post.achieved?).to be false
      end
    end
  end

  describe "#achieve!" do
    let(:post) { create(:post) }

    context "未達成の場合" do
      it "achieved_atを設定する" do
        expect { post.achieve! }.to change { post.achieved_at }.from(nil)
      end

      it "達成済みになる" do
        post.achieve!
        expect(post.achieved?).to be true
      end
    end

    context "既に達成済みの場合" do
      before { post.update(achieved_at: 1.day.ago) }

      it "achieved_atは変更されない" do
        expect { post.achieve! }.not_to change { post.reload.achieved_at }
      end
    end
  end

  describe "YouTube情報自動取得" do
    let(:user) { create(:user) }
    let(:youtube_url) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }

    before do
      allow(YoutubeService).to receive(:fetch_video_info).and_return({
        title: 'Test Video Title',
        channel_name: 'Test Channel'
      })
    end

    context "新規作成時" do
      it "YouTube情報を自動取得する" do
        post = create(:post, user: user, youtube_url: youtube_url)

        expect(post.youtube_title).to eq('Test Video Title')
        expect(post.youtube_channel_name).to eq('Test Channel')
      end
    end

    context "更新時にyoutube_urlが変更された場合" do
      let(:post) { create(:post, user: user, youtube_url: youtube_url) }

      it "YouTube情報を再取得する" do
        allow(YoutubeService).to receive(:fetch_video_info).and_return({
          title: 'Updated Title',
          channel_name: 'Updated Channel'
        })

        post.update(youtube_url: 'https://www.youtube.com/watch?v=abc123')

        expect(post.youtube_title).to eq('Updated Title')
        expect(post.youtube_channel_name).to eq('Updated Channel')
      end
    end

    context "更新時にyoutube_urlが変更されない場合" do
      it "YouTube情報を再取得しない" do
        post = create(:post, user: user, youtube_url: youtube_url)
        expect(post.youtube_title).to eq('Test Video Title')

        # モックをクリアして、呼ばれないことを確認
        expect(YoutubeService).not_to receive(:fetch_video_info)

        post.update(trigger_content: '新しいきっかけ')

        # 既存の値がそのまま保持される
        expect(post.youtube_title).to eq('Test Video Title')
      end
    end

    context "API取得に失敗した場合" do
      before do
        allow(YoutubeService).to receive(:fetch_video_info).and_return(nil)
      end

      it "投稿は保存される（YouTube情報はnil）" do
        post = create(:post, user: user, youtube_url: youtube_url)

        expect(post).to be_persisted
        expect(post.youtube_title).to be_nil
        expect(post.youtube_channel_name).to be_nil
      end
    end
  end
end
