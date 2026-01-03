# spec/models/post_comparison_spec.rb
require 'rails_helper'

RSpec.describe PostComparison, type: :model do
  let(:user) { create(:user) }
  let(:source_post) { create(:post, user: user) }
  let(:target_post) { create(:post, user: user) }

  describe 'associations' do
    it { should belong_to(:source_post).class_name('Post') }
    it { should belong_to(:target_post).class_name('Post') }
  end

  describe 'validations' do
    it '同じ比較の重複を許可しない' do
      create(:post_comparison, source_post: source_post, target_post: target_post)
      duplicate = build(:post_comparison, source_post: source_post, target_post: target_post)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:target_post_id]).to include('は既に比較対象として追加されています')
    end

    it '自己参照を許可しない' do
      comparison = build(:post_comparison, source_post: source_post, target_post: source_post)
      expect(comparison).not_to be_valid
      expect(comparison.errors[:target_post]).to include('自分自身の投稿とは比較できません')
    end
  end

  describe 'Post associations' do
    let!(:comparison) { create(:post_comparison, source_post: source_post, target_post: target_post) }

    it 'source_postからcompared_postsを取得できる' do
      expect(source_post.compared_posts).to include(target_post)
    end

    it 'target_postからcomparing_postsを取得できる' do
      expect(target_post.comparing_posts).to include(source_post)
    end

    it '比較は一方向のみ（A→Bが存在してもB→Aは別途必要）' do
      expect(target_post.compared_posts).not_to include(source_post)
    end
  end
end
