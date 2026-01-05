import { Controller } from "@hotwired/stimulus"

// クイズ回答用Stimulusコントローラー
export default class extends Controller {
  static targets = [
    "loading", "empty", "questions", "answered", "error",
    "currentQuestion", "totalQuestions", "questionContainer",
    "prevBtn", "nextBtn", "submitBtn",
    "lastScore", "lastTotal", "errorMessage"
  ]

  connect() {
    this.quiz = null
    this.answers = {}
    this.currentIndex = 0
    this.postId = null

    // 初期状態を設定（空状態のみ表示）
    this.initializeState()
  }

  initializeState() {
    // 全ての状態を非表示
    if (this.hasLoadingTarget) this.loadingTarget.style.display = 'none'
    if (this.hasQuestionsTarget) this.questionsTarget.style.display = 'none'
    if (this.hasAnsweredTarget) this.answeredTarget.style.display = 'none'
    if (this.hasErrorTarget) this.errorTarget.style.display = 'none'

    // 空状態のみ表示
    if (this.hasEmptyTarget) this.emptyTarget.style.display = 'flex'
  }

  // クイズ生成
  async generate() {
    const videoId = this.getVideoId()
    if (!videoId) {
      this.showError("動画URLを先に入力してください")
      return
    }

    // PostIDを取得または作成
    this.postId = await this.getOrCreatePostId()
    if (!this.postId) {
      this.showError("投稿の作成に失敗しました")
      return
    }

    this.showLoading()

    try {
      const response = await fetch(`/posts/${this.postId}/quiz/generate`, {
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
      <div class="quiz-question">
        <h4 class="quiz-question-text">${question.question_text}</h4>
        <div class="quiz-options">
          ${question.options.map((option, index) => `
            <label class="quiz-option ${selectedAnswer === (index + 1) ? 'quiz-option-selected' : ''}">
              <input type="radio"
                     name="quiz_answer_${question.id}"
                     value="${index + 1}"
                     ${selectedAnswer === (index + 1) ? 'checked' : ''}
                     data-action="change->quiz#selectAnswer"
                     data-question-id="${question.id}">
              <span class="quiz-option-marker">${String.fromCharCode(65 + index)}</span>
              <span class="quiz-option-text">${option}</span>
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

    // 選択スタイルを更新
    const options = this.questionContainerTarget.querySelectorAll('.quiz-option')
    options.forEach((opt, index) => {
      opt.classList.toggle('quiz-option-selected', (index + 1) === value)
    })

    this.updateNavigation()
  }

  // ナビゲーション更新
  updateNavigation() {
    const isFirst = this.currentIndex === 0
    const isLast = this.currentIndex === this.quiz.questions.length - 1
    const allAnswered = this.quiz.questions.every(q => this.answers[q.id])

    this.prevBtnTarget.disabled = isFirst

    if (isLast) {
      this.nextBtnTarget.style.display = 'none'
      this.submitBtnTarget.style.display = 'inline-flex'
      this.submitBtnTarget.disabled = !allAnswered
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
    if (!this.postId) {
      this.showError("投稿情報がありません")
      return
    }

    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = "送信中..."

    try {
      const response = await fetch(`/posts/${this.postId}/quiz/submit`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ answers: this.answers })
      })

      const data = await response.json()

      if (data.success) {
        // 詳細ページにリダイレクト
        window.location.href = `/posts/${data.post_id}?quiz_completed=true`
      } else {
        this.showError(data.error || "回答の送信に失敗しました")
        this.submitBtnTarget.disabled = false
        this.submitBtnTarget.textContent = "回答を送信"
      }
    } catch (error) {
      console.error("Quiz submit error:", error)
      this.showError("回答の送信に失敗しました")
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
    this.hideAll()
    this.emptyTarget.style.display = 'flex'
  }

  // 各状態の表示制御
  showLoading() {
    this.hideAll()
    this.loadingTarget.style.display = 'flex'
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

  // YouTube動画IDを取得
  getVideoId() {
    const urlField = document.querySelector('[data-youtube-search-target="urlField"]')
    if (!urlField || !urlField.value) return null

    const url = urlField.value
    let videoId = null

    if (url.includes("youtube.com/watch")) {
      const urlParams = new URLSearchParams(new URL(url).search)
      videoId = urlParams.get("v")
    } else if (url.includes("youtu.be/")) {
      videoId = url.split("youtu.be/")[1]?.split("?")[0]
    }

    return videoId
  }

  // PostIDを取得または作成
  async getOrCreatePostId() {
    const urlField = document.querySelector('[data-youtube-search-target="urlField"]')
    if (!urlField || !urlField.value) return null

    try {
      // まず既存のPostを検索、なければ作成
      const response = await fetch('/posts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          post: { youtube_url: urlField.value },
          silent: true // サイレント投稿フラグ
        })
      })

      const data = await response.json()
      return data.id || data.post_id
    } catch (error) {
      console.error("Failed to get/create post:", error)
      return null
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
