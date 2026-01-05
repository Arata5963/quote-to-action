# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :post
  has_many :quiz_questions, dependent: :destroy
  has_many :quiz_answers, dependent: :destroy

  validates :post_id, uniqueness: true

  def answered_by?(user)
    return false unless user

    quiz_answers.exists?(user_id: user.id)
  end

  def latest_answer_for(user)
    return nil unless user

    quiz_answers.where(user_id: user.id).order(created_at: :desc).first
  end
end
