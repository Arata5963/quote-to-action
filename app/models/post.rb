class Post < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy

  mount_uploader :image, ImageUploader
  scope :recent, -> { order(created_at: :desc) }

  validates :trigger_content, presence: true, length: { minimum: 1, maximum: 100 }
  validates :action_plan,    presence: true, length: { minimum: 1, maximum: 100 }
end
