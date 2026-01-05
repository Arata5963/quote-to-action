# frozen_string_literal: true

class QuizAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :quiz

  validates :score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_questions, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def percentage
    return 0 if total_questions.zero?

    (score.to_f / total_questions * 100).round
  end

  def perfect?
    score == total_questions
  end
end
