class PostComparison < ApplicationRecord
  belongs_to :source_post, class_name: 'Post'
  belongs_to :target_post, class_name: 'Post'

  # 同じ比較の重複を防ぐ
  validates :target_post_id, uniqueness: { scope: :source_post_id, message: 'は既に比較対象として追加されています' }

  # 自己参照を防ぐ
  validate :cannot_compare_to_self

  private

  def cannot_compare_to_self
    if source_post_id == target_post_id
      errors.add(:target_post, '自分自身の投稿とは比較できません')
    end
  end
end
