import { Controller } from "@hotwired/stimulus"

// 詳細画面用クイズコントローラー
export default class extends Controller {
  static targets = [
    "loading", "empty", "questions", "answered", "error",
    "currentQuestion", "totalQuestions", "questionContainer",
    "prevBtn", "nextBtn", "submitBtn",
    "lastScore", "lastTotal", "errorMessage"
  ]

  static values = {
    postId: Number,
    hasQuiz: Boolean,
    answered: Boolean
  }

  connect() {
    this.quiz = null
    this.answers = {}
    this.currentIndex = 0

    // 既存クイズがあり、未回答の場合はクイズデータを読み込む
    if (this.hasQuizValue && !this.answeredValue) {
      this.loadQuiz()
    }
  }

  // 既存クイズを読み込む
  async loadQuiz() {
    this.showLoading()

    try {
      const response = await fetch(`/posts/${this.postIdValue}/quiz`, {
        headers: {
          "Accept": "application/json"
        }
      })

      const data = await response.json()

      if (data.success && data.quiz) {
        this.quiz = data.quiz
        if (data.answered) {
          this.showAnswered(data.latest_answer)
        } else {
          this.showQuestions()
        }
      } else {
        this.showEmpty()
      }
    } catch (error) {
      console.error("Quiz load error:", error)
      this.showError("クイズの読み込みに失敗しました")
    }
  }

  // クイズ生成
  async generate() {
    this.showLoading()

    try {
      const response = await fetch(`/posts/${this.postIdValue}/quiz/generate`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      const data = await response.json()

      if (data.success) {
        this.quiz = data.quiz
        this.showQuestions()
      } else {
        this.showError(data.error || "クイズの生成に失敗しました")
      }
    } catch (error) {
      console.error("Quiz generation error:", error)
      this.showError("クイズの生成に失敗しました")
    }
  }

  // クイズを表示
  showQuestions() {
    this.hideAll()
    this.questionsTarget.style.display = 'block'

    // 問題数を設定
    this.totalQuestionsTarget.textContent = this.quiz.questions.length

    // 最初の問題を表示
    this.currentIndex = 0
    this.renderQuestion()
  }

  // 問題をレンダリング
  renderQuestion() {
    const question = this.quiz.questions[this.currentIndex]
    this.currentQuestionTarget.textContent = this.currentIndex + 1

    const selectedAnswer = this.answers[question.id]

    this.questionContainerTarget.innerHTML = `
      <div style="background: white; border-radius: 12px; padding: 20px; border: 1px solid #e5e7eb;">
        <h4 style="font-size: 16px; font-weight: 500; color: #1a1a1a; margin-bottom: 20px; line-height: 1.6;">
          ${question.question_text}
        </h4>
        <div style="display: flex; flex-direction: column; gap: 10px;">
          ${question.options.map((option, index) => `
            <label style="display: flex; align-items: center; gap: 12px; padding: 14px 16px; background: ${selectedAnswer === (index + 1) ? '#f0f9ff' : '#f9fafb'}; border: 2px solid ${selectedAnswer === (index + 1) ? '#3b82f6' : '#e5e7eb'}; border-radius: 8px; cursor: pointer; transition: all 0.2s;">
              <input type="radio"
                     name="quiz_answer_${question.id}"
                     value="${index + 1}"
                     ${selectedAnswer === (index + 1) ? 'checked' : ''}
                     data-action="change->detail-quiz#selectAnswer"
                     data-question-id="${question.id}"
                     style="width: 18px; height: 18px; accent-color: #3b82f6;">
              <span style="display: inline-flex; align-items: center; justify-content: center; width: 24px; height: 24px; background: ${selectedAnswer === (index + 1) ? '#3b82f6' : '#e5e7eb'}; color: ${selectedAnswer === (index + 1) ? 'white' : '#6b7280'}; font-size: 12px; font-weight: 600; border-radius: 4px;">
                ${String.fromCharCode(65 + index)}
              </span>
              <span style="flex: 1; font-size: 14px; color: #374151;">${option}</span>
            </label>
          `).join('')}
        </div>
      </div>
    `

    this.updateNavigation()
  }

  // 回答を選択
  selectAnswer(event) {
    const questionId = event.target.dataset.questionId
    const value = parseInt(event.target.value)
    this.answers[questionId] = value

    // スタイルを即座に更新
    this.renderQuestion()
  }

  // ナビゲーション更新
  updateNavigation() {
    const isFirst = this.currentIndex === 0
    const isLast = this.currentIndex === this.quiz.questions.length - 1
    const allAnswered = this.quiz.questions.every(q => this.answers[q.id])

    this.prevBtnTarget.disabled = isFirst
    this.prevBtnTarget.style.opacity = isFirst ? '0.5' : '1'
    this.prevBtnTarget.style.cursor = isFirst ? 'not-allowed' : 'pointer'

    if (isLast) {
      this.nextBtnTarget.style.display = 'none'
      this.submitBtnTarget.style.display = 'inline-flex'
      this.submitBtnTarget.disabled = !allAnswered
      this.submitBtnTarget.style.opacity = allAnswered ? '1' : '0.5'
    } else {
      this.nextBtnTarget.style.display = 'inline-flex'
      this.submitBtnTarget.style.display = 'none'
    }
  }

  // 前の問題
  prevQuestion() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.renderQuestion()
    }
  }

  // 次の問題
  nextQuestion() {
    if (this.currentIndex < this.quiz.questions.length - 1) {
      this.currentIndex++
      this.renderQuestion()
    }
  }

  // 回答を送信
  async submit() {
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = "送信中..."

    try {
      const response = await fetch(`/posts/${this.postIdValue}/quiz/submit`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ answers: this.answers })
      })

      const data = await response.json()

      if (data.success) {
        // 結果を表示
        this.showAnswered({
          score: data.score,
          total_questions: data.total
        })
      } else {
        this.showError(data.error || "回答の送信に失敗しました")
      }
    } catch (error) {
      console.error("Quiz submit error:", error)
      this.showError("回答の送信に失敗しました")
    } finally {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = "回答を送信"
    }
  }

  // 再挑戦
  retake() {
    this.answers = {}
    this.currentIndex = 0
    this.showQuestions()
  }

  // 再試行
  retry() {
    if (this.hasQuizValue) {
      this.loadQuiz()
    } else {
      this.showEmpty()
    }
  }

  // 各状態の表示制御
  showLoading() {
    this.hideAll()
    this.loadingTarget.style.display = 'flex'
  }

  showEmpty() {
    this.hideAll()
    this.emptyTarget.style.display = 'flex'
  }

  showAnswered(answer) {
    this.hideAll()
    this.answeredTarget.style.display = 'flex'

    if (answer) {
      this.lastScoreTarget.textContent = answer.score
      this.lastTotalTarget.textContent = answer.total_questions
    }
  }

  showError(message) {
    this.hideAll()
    this.errorMessageTarget.textContent = message
    this.errorTarget.style.display = 'flex'
  }

  hideAll() {
    if (this.hasLoadingTarget) this.loadingTarget.style.display = 'none'
    if (this.hasEmptyTarget) this.emptyTarget.style.display = 'none'
    if (this.hasQuestionsTarget) this.questionsTarget.style.display = 'none'
    if (this.hasAnsweredTarget) this.answeredTarget.style.display = 'none'
    if (this.hasErrorTarget) this.errorTarget.style.display = 'none'
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
