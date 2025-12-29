# spec/models/post_methods_spec.rb
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe '.ransackable_attributes' do
    it '検索可能な属性のリストを返す' do
      attributes = Post.ransackable_attributes
      expect(attributes).to include('action_plan')
      expect(attributes).to include('youtube_title')
      expect(attributes).to include('youtube_channel_name')
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

    it '投稿を削除すると応援も削除される' do
      create(:cheer, user: user, post: post)

      expect {
        post.destroy
      }.to change(Cheer, :count).by(-1)
    end

    it '投稿を削除すると全ての関連データが削除される' do
      create(:achievement, user: user, post: post, achieved_at: Date.current)
      create(:comment, user: user, post: post)
      create(:cheer, user: user, post: post)

      expect {
        post.destroy
      }.to change {
        [ Achievement.count, Comment.count, Cheer.count ]
      }.from([ 1, 1, 1 ]).to([ 0, 0, 0 ])
    end
  end
end
