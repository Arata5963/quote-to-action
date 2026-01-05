import { Controller } from "@hotwired/stimulus"

// 引用ショーケースコントローラー
// タイプライター効果とナビゲーションを管理
export default class extends Controller {
  static targets = [
    "card", "progress", "prevBtn", "nextBtn",
    "autoplayToggle", "currentIndex"
  ]

  static values = {
    autoplayInterval: { type: Number, default: 6000 },
    typingSpeed: { type: Number, default: 40 }
  }

  connect() {
    console.log("QuotesShowcase controller connected!")
    console.log("Card targets found:", this.cardTargets.length)

    this.currentIndex = 0
    this.isTyping = false
    this.autoplayTimer = null
    this.typingTimer = null

    // 引用テキストを配列で保持
    this.quotes = this.cardTargets.map(card => {
      console.log("Card dataset:", card.dataset)
      return card.dataset.quoteText || ""
    })

    console.log("Quotes loaded:", this.quotes)

    // 最初の引用のタイプライター開始
    if (this.quotes.length > 0 && this.quotes[0]) {
      console.log("Starting typewriter in 500ms...")
      setTimeout(() => this.startTyping(), 500)
    } else {
      console.log("No quotes to type, showing static text")
    }

    // キーボードナビゲーション
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)

    // 直接イベントリスナーを追加（data-action が動かない場合の対策）
    this.bindClickEvents()
  }

  bindClickEvents() {
    // プログレスドット
    const dots = this.element.querySelectorAll(".quotes-progress-dot")
    console.log("Binding click to dots:", dots.length)
    dots.forEach((dot, i) => {
      dot.addEventListener("click", (e) => {
        e.preventDefault()
        console.log("Dot clicked:", i)
        if (i !== this.currentIndex) {
          this.showQuote(i, i > this.currentIndex ? "up" : "down")
        }
      })
    })

    // Prev/Next ボタン
    const prevBtn = this.element.querySelector(".quotes-nav-btn[aria-label='前の引用']")
    const nextBtn = this.element.querySelector(".quotes-nav-btn[aria-label='次の引用']")

    if (prevBtn) {
      prevBtn.addEventListener("click", (e) => {
        e.preventDefault()
        console.log("Prev clicked")
        this.prev()
      })
    }

    if (nextBtn) {
      nextBtn.addEventListener("click", (e) => {
        e.preventDefault()
        console.log("Next clicked")
        this.next()
      })
    }

    // 自動再生トグル
    const autoplayToggle = this.element.querySelector(".quotes-autoplay-toggle")
    if (autoplayToggle) {
      autoplayToggle.addEventListener("click", (e) => {
        e.preventDefault()
        console.log("Autoplay toggle clicked")
        this.toggleAutoplay()
      })
    }
  }

  disconnect() {
    this.stopAutoplay()
    this.clearTyping()
    document.removeEventListener("keydown", this.handleKeydown)
  }

  // キーボードナビゲーション
  handleKeydown(event) {
    switch (event.key) {
      case "ArrowLeft":
        event.preventDefault()
        this.prev()
        break
      case "ArrowRight":
        event.preventDefault()
        this.next()
        break
      case " ":
        event.preventDefault()
        this.toggleAutoplay()
        break
    }
  }

  // タイプライター効果を開始
  startTyping() {
    const card = this.cardTargets[this.currentIndex]
    if (!card) {
      console.error("Card not found for index:", this.currentIndex)
      return
    }

    // カード内の要素を直接取得
    const textElement = card.querySelector(".quote-text-inner")
    const cursorElement = card.querySelector(".quote-cursor")
    const authorElement = card.querySelector(".quote-author")

    if (!textElement) {
      console.error("Text element not found in card")
      return
    }

    const text = this.quotes[this.currentIndex]
    if (!text) {
      console.error("No text for quote index:", this.currentIndex)
      return
    }

    console.log("Starting typing for:", text)

    this.isTyping = true
    textElement.innerHTML = ""

    // カーソル表示
    if (cursorElement) {
      cursorElement.classList.remove("hidden")
    }

    // 著者非表示
    if (authorElement) {
      authorElement.classList.remove("visible")
    }

    let charIndex = 0
    const typeChar = () => {
      if (charIndex < text.length) {
        const char = text[charIndex]
        const span = document.createElement("span")
        span.className = "quote-char"
        span.style.opacity = "0"
        span.style.animation = "char-appear 0.1s ease forwards"

        if (char === "\n") {
          textElement.appendChild(document.createElement("br"))
        } else {
          span.textContent = char
          textElement.appendChild(span)
        }

        charIndex++
        this.typingTimer = setTimeout(typeChar, this.typingSpeedValue)
      } else {
        // タイピング完了
        this.isTyping = false

        // カーソルを消す
        if (cursorElement) {
          setTimeout(() => {
            cursorElement.classList.add("hidden")
          }, 500)
        }

        // 著者表示
        if (authorElement) {
          setTimeout(() => {
            authorElement.classList.add("visible")
          }, 300)
        }

        // オートプレイ中なら次へ
        if (this.autoplayTimer !== null) {
          this.scheduleNextAutoplay()
        }
      }
    }

    // 開始
    typeChar()
  }

  // タイピングをクリア
  clearTyping() {
    if (this.typingTimer) {
      clearTimeout(this.typingTimer)
      this.typingTimer = null
    }
    this.isTyping = false
  }

  // 指定インデックスに移動
  goTo(event) {
    console.log("goTo called", event.currentTarget.dataset)
    const index = parseInt(event.currentTarget.dataset.index)
    console.log("Going to index:", index, "Current:", this.currentIndex)
    if (index === this.currentIndex) return
    this.showQuote(index, index > this.currentIndex ? "up" : "down")
  }

  // 前の引用
  prev() {
    console.log("prev called, currentIndex:", this.currentIndex)
    if (this.currentIndex > 0) {
      this.showQuote(this.currentIndex - 1, "down")
    }
  }

  // 次の引用
  next() {
    console.log("next called, currentIndex:", this.currentIndex, "total:", this.quotes.length)
    if (this.currentIndex < this.quotes.length - 1) {
      this.showQuote(this.currentIndex + 1, "up")
    } else if (this.autoplayTimer !== null) {
      // オートプレイ中は最初に戻る
      this.showQuote(0, "up")
    }
  }

  // 引用を表示
  showQuote(index, direction = "up") {
    if (index < 0 || index >= this.quotes.length) return

    this.clearTyping()

    const prevCard = this.cardTargets[this.currentIndex]
    const nextCard = this.cardTargets[index]

    // 前のカードをアニメーションで消す
    if (prevCard) {
      prevCard.classList.remove("active")
      prevCard.classList.add(direction === "up" ? "exit-up" : "exit-down")

      setTimeout(() => {
        prevCard.classList.remove("exit-up", "exit-down")
        // テキストをクリア
        const textEl = prevCard.querySelector(".quote-text-inner")
        if (textEl) textEl.innerHTML = ""
      }, 800)
    }

    // 次のカードを表示
    if (nextCard) {
      nextCard.classList.add("active")
    }

    this.currentIndex = index
    this.updateUI()

    // 少し遅延してタイプライター開始
    setTimeout(() => this.startTyping(), 400)
  }

  // UI更新
  updateUI() {
    // プログレスドット
    const dots = this.element.querySelectorAll(".quotes-progress-dot")
    dots.forEach((dot, i) => {
      dot.classList.toggle("active", i === this.currentIndex)
    })

    // ナビボタン
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.disabled = this.currentIndex === 0
    }
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.disabled = this.currentIndex === this.quotes.length - 1 && this.autoplayTimer === null
    }

    // カウンター
    if (this.hasCurrentIndexTarget) {
      this.currentIndexTarget.textContent = this.currentIndex + 1
    }
  }

  // オートプレイ切り替え
  toggleAutoplay() {
    if (this.autoplayTimer !== null) {
      this.stopAutoplay()
    } else {
      this.startAutoplay()
    }
  }

  // オートプレイ開始
  startAutoplay() {
    if (this.hasAutoplayToggleTarget) {
      this.autoplayToggleTarget.classList.add("active")
    }

    // 次のスケジュールはタイピング完了後に行う
    if (!this.isTyping) {
      this.scheduleNextAutoplay()
    } else {
      // タイピング中の場合、フラグだけ立てる
      this.autoplayTimer = "pending"
    }

    // 次へボタンを有効化（ループ可能に）
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.disabled = false
    }
  }

  // 次のオートプレイをスケジュール
  scheduleNextAutoplay() {
    const textLength = this.quotes[this.currentIndex]?.length || 0
    const delay = Math.max(2000, this.autoplayIntervalValue - (textLength * this.typingSpeedValue))

    this.autoplayTimer = setTimeout(() => {
      this.next()
    }, delay)
  }

  // オートプレイ停止
  stopAutoplay() {
    if (this.autoplayTimer && this.autoplayTimer !== "pending") {
      clearTimeout(this.autoplayTimer)
    }
    this.autoplayTimer = null

    if (this.hasAutoplayToggleTarget) {
      this.autoplayToggleTarget.classList.remove("active")
    }

    // 最後の引用なら次へボタンを無効化
    if (this.hasNextBtnTarget && this.currentIndex === this.quotes.length - 1) {
      this.nextBtnTarget.disabled = true
    }
  }
}
