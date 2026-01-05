# frozen_string_literal: true

class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: %i[show generate submit]
  before_action :set_quiz, only: %i[show submit]

  # GET /posts/:post_id/quiz
  # クイズ表示（既存クイズまたは生成を促す画面）
  def show
    if @quiz
      render json: {
        success: true,
        quiz: quiz_json(@quiz),
        answered: @quiz.answered_by?(current_user),
        latest_answer: answer_json(@quiz.latest_answer_for(current_user))
      }
    else
      render json: { success: true, quiz: nil }
    end
  end

  # POST /posts/:post_id/quiz/generate
  # AIでクイズを生成
  def generate
    # 既存クイズがあればそれを返す
    if @post.quiz
      return render json: {
        success: true,
        quiz: quiz_json(@post.quiz),
        message: "既存のクイズを表示しています"
      }
    end

    # AIでクイズを生成
    result = GeminiService.generate_quiz(
      video_id: @post.youtube_video_id,
      title: @post.youtube_title
    )

    unless result[:success]
      return render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end

    # クイズをDBに保存
    ActiveRecord::Base.transaction do
      quiz = @post.create_quiz!

      result[:questions].each_with_index do |q, index|
        quiz.quiz_questions.create!(
          question_text: q["question_text"],
          option_1: q["option_1"],
          option_2: q["option_2"],
          option_3: q["option_3"],
          option_4: q["option_4"],
          correct_option: q["correct_option"].to_i,
          position: index + 1
        )
      end

      render json: {
        success: true,
        quiz: quiz_json(quiz),
        message: "クイズを生成しました"
      }
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: "クイズの保存に失敗しました: #{e.message}" }, status: :unprocessable_entity
  end

  # POST /posts/:post_id/quiz/submit
  # クイズ回答を提出
  def submit
    return render json: { success: false, error: "クイズが見つかりません" }, status: :not_found unless @quiz

    answers = params[:answers] # { "1" => 2, "2" => 3, ... } question_id => selected_option
    return render json: { success: false, error: "回答がありません" }, status: :unprocessable_entity if answers.blank?

    # 採点
    score = 0
    results = []

    @quiz.quiz_questions.each do |question|
      user_answer = answers[question.id.to_s].to_i
      is_correct = question.correct?(user_answer)
      score += 1 if is_correct

      results << {
        question_id: question.id,
        question_text: question.question_text,
        user_answer: user_answer,
        correct_option: question.correct_option,
        is_correct: is_correct,
        options: question.options
      }
    end

    # 回答を保存
    quiz_answer = @quiz.quiz_answers.create!(
      user: current_user,
      score: score,
      total_questions: @quiz.quiz_questions.count
    )

    render json: {
      success: true,
      score: score,
      total: @quiz.quiz_questions.count,
      percentage: quiz_answer.percentage,
      perfect: quiz_answer.perfect?,
      results: results,
      post_id: @post.id
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: "回答の保存に失敗しました: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_quiz
    @quiz = @post.quiz
  end

  def quiz_json(quiz)
    return nil unless quiz

    {
      id: quiz.id,
      questions: quiz.quiz_questions.map do |q|
        {
          id: q.id,
          question_text: q.question_text,
          options: q.options,
          position: q.position
        }
      end
    }
  end

  def answer_json(answer)
    return nil unless answer

    {
      score: answer.score,
      total: answer.total_questions,
      percentage: answer.percentage,
      perfect: answer.perfect?,
      answered_at: answer.created_at
    }
  end
end
