# frozen_string_literal: true

class QuizQuestion < ApplicationRecord
  belongs_to :quiz

  validates :question_text, presence: true
  validates :option_1, :option_2, :option_3, :option_4, presence: true
  validates :correct_option, presence: true, inclusion: { in: 1..4 }
  validates :position, presence: true

  default_scope { order(:position) }

  def options
    [option_1, option_2, option_3, option_4]
  end

  def correct?(answer)
    correct_option == answer.to_i
  end
end
