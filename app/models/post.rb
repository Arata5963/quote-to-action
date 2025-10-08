class Post < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  # 投稿は複数のコメントを持つ
  # dependent: :destroy = 投稿削除時に関連コメントも全て削除
  has_many :comments, dependent: :destroy


  mount_uploader :image, ImageUploader
  scope :recent, -> { order(created_at: :desc) }

  validates :trigger_content, presence: true, length: { minimum: 1, maximum: 100 }
  validates :action_plan,    presence: true, length: { minimum: 1, maximum: 100 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[trigger_content action_plan created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user achievements]
  end

end
