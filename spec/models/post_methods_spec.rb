# spec/models/post_methods_spec.rb
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe '.ransackable_attributes' do
    it '検索可能な属性のリストを返す' do
      attributes = Post.ransackable_attributes
      expect(attributes).to include('trigger_content')
      expect(attributes).to include('action_plan')
      expect(attributes).to include('created_at')
    end

    it '検索可能な属性は配列である' do
      attributes = Post.ransackable_attributes
      expect(attributes).to be_an(Array)
    end

    it 'すべての検索可能属性が文字列である' do
      attributes = Post.ransackable_attributes
      expect(attributes).to all(be_a(String))
    end
  end

  describe '.ransackable_associations' do
    it '検索可能なアソシエーションのリストを返す' do
      associations = Post.ransackable_associations
      expect(associations).to include('user')
      expect(associations).to include('achievements')
    end

    it '検索可能なアソシエーションは配列である' do
      associations = Post.ransackable_associations
      expect(associations).to be_an(Array)
    end

    it 'すべての検索可能アソシエーションが文字列である' do
      associations = Post.ransackable_associations
      expect(associations).to all(be_a(String))
    end
  end

  describe 'image (CarrierWave)' do
    let(:user) { create(:user) }

    context '画像がアップロードされていない場合' do
      let(:post) { create(:post, user: user) }

      it 'imageはnilまたは空である' do
        expect(post.image.present?).to be_falsy
      end
    end

    context '画像がアップロードされている場合' do
      let(:post_with_image) do
        create(:post, user: user, image: fixture_file_upload('spec/fixtures/files/sample_post.jpg', 'image/jpeg'))
      end

      it 'imageが存在する' do
        expect(post_with_image.image.present?).to be true
      end

      it 'imageのURLが生成される' do
        expect(post_with_image.image.url).to be_present
      end

      it 'サムネイルURLが生成される' do
        expect(post_with_image.image.thumb.url).to be_present
      end

      it 'image_identifierが設定される' do
        expect(post_with_image.image_identifier).to be_present
      end
    end
  end

  describe 'category enum' do
    let(:user) { create(:user) }

    it '各カテゴリが正しく設定できる' do
      Post.categories.each_key do |category|
        post = build(:post, user: user, category: category)
        expect(post).to be_valid
        expect(post.category).to eq(category)
      end
    end

    it 'category_text? などのクエリメソッドが使える' do
      post = create(:post, user: user, category: :text)
      expect(post.category_text?).to be true
      expect(post.category_video?).to be false
    end

    it '存在しないカテゴリを設定するとエラー' do
      expect {
        build(:post, user: user, category: :invalid_category)
      }.to raise_error(ArgumentError)
    end
  end

  describe 'related_url validation' do
    let(:user) { create(:user) }

    context '有効なURL' do
      it 'httpsのURLが保存できる' do
        post = build(:post, user: user, related_url: 'https://example.com')
        expect(post).to be_valid
      end

      it 'httpのURLが保存できる' do
        post = build(:post, user: user, related_url: 'http://example.com')
        expect(post).to be_valid
      end

      it '空白の場合も有効' do
        post = build(:post, user: user, related_url: '')
        expect(post).to be_valid
      end

      it 'nilの場合も有効' do
        post = build(:post, user: user, related_url: nil)
        expect(post).to be_valid
      end
    end

    context '無効なURL' do
      it 'http(s)で始まらないURLはエラー' do
        post = build(:post, user: user, related_url: 'example.com')
        expect(post).not_to be_valid
        expect(post.errors[:related_url]).to be_present
      end

      it '不正な形式のURLはエラー' do
        post = build(:post, user: user, related_url: 'not-a-url')
        expect(post).not_to be_valid
        expect(post.errors[:related_url]).to be_present
      end

      it '500文字を超えるURLはエラー' do
        long_url = 'https://example.com/' + 'a' * 500
        post = build(:post, user: user, related_url: long_url)
        expect(post).not_to be_valid
        expect(post.errors[:related_url]).to be_present
      end
    end
  end

  describe 'dependent destroy' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    it '投稿を削除すると達成記録も削除される' do
      create(:achievement, user: user, post: post, awarded_at: Date.current)
      
      expect {
        post.destroy
      }.to change(Achievement, :count).by(-1)
    end

    it '投稿を削除するとコメントも削除される' do
      create(:comment, user: user, post: post)
      
      expect {
        post.destroy
      }.to change(Comment, :count).by(-1)
    end

    it '投稿を削除するといいねも削除される' do
      create(:like, user: user, post: post)
      
      expect {
        post.destroy
      }.to change(Like, :count).by(-1)
    end

    it '投稿を削除すると全ての関連データが削除される' do
      create(:achievement, user: user, post: post, awarded_at: Date.current)
      create(:comment, user: user, post: post)
      create(:like, user: user, post: post)
      
      expect {
        post.destroy
      }.to change {
        [Achievement.count, Comment.count, Like.count]
      }.from([1, 1, 1]).to([0, 0, 0])
    end
  end
end