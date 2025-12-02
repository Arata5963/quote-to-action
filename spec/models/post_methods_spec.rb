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

  describe 'category enum' do
    let(:user) { create(:user) }

    it '各カテゴリが正しく設定できる' do
      Post.categories.each_key do |category|
        post = build(:post, user: user, category: category)
        expect(post).to be_valid
        expect(post.category).to eq(category)
      end
    end

    it 'category_music? などのクエリメソッドが使える' do
      post = create(:post, user: user, category: :music)
      expect(post.category_music?).to be true
      expect(post.category_education?).to be false
    end

    it '存在しないカテゴリを設定するとエラー' do
      expect {
        build(:post, user: user, category: :invalid_category)
      }.to raise_error(ArgumentError)
    end
  end

  describe 'dependent destroy' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    it '投稿を削除すると達成記録も削除される' do
      create(:achievement, user: user, post: post, achieved_at: Date.current)

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
      create(:achievement, user: user, post: post, achieved_at: Date.current)
      create(:comment, user: user, post: post)
      create(:like, user: user, post: post)

      expect {
        post.destroy
      }.to change {
        [ Achievement.count, Comment.count, Like.count ]
      }.from([ 1, 1, 1 ]).to([ 0, 0, 0 ])
    end
  end
end
