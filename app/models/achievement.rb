class Achievement < ApplicationRecord
  belongs_to :user
  belongs_to :post
  validates :awarded_at, presence: true
  validates :post_id, uniqueness: {
    scope: [ :user_id, :awarded_at ],
    message: "今日はすでに達成済みです"
  }

  scope :today, -> { where(awarded_at: Date.current) }
end
