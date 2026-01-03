// app/javascript/controllers/quote_animation_controller.js
// 引用テキストの吹き出しアニメーションコントローラー
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quote"]
  static values = {
    delay: { type: Number, default: 100 } // 単語間の遅延(ms)
  }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      { threshold: 0.2, rootMargin: "0px 0px -50px 0px" }
    )

    this.quoteTargets.forEach((quote) => {
      this.observer.observe(quote)
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersection(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting && !entry.target.dataset.animated) {
        entry.target.dataset.animated = "true"
        this.animateQuote(entry.target)
      }
    })
  }

  animateQuote(element) {
    const textContainer = element.querySelector("[data-quote-text]")
    if (!textContainer) return

    const text = textContainer.textContent.trim()
    // 日本語対応: 文字単位で分割（空白がない場合も考慮）
    const segments = this.splitText(text)

    // テキストをクリア
    textContainer.innerHTML = ""

    // 各セグメントをspanでラップしてアニメーション
    segments.forEach((segment, index) => {
      const span = document.createElement("span")
      span.textContent = segment
      span.className = "quote-word"
      span.style.animationDelay = `${index * this.delayValue}ms`
      textContainer.appendChild(span)
    })

    // 吹き出し全体のフェードイン
    element.classList.add("quote-bubble-visible")
  }

  // テキストを適切に分割（日本語・英語混在対応）
  splitText(text) {
    // 空白で分割可能な場合は単語単位、そうでなければ文字単位（ただし2-3文字ずつ）
    if (text.includes(" ")) {
      return text.split(/(\s+)/).filter(s => s.length > 0)
    } else {
      // 日本語の場合は2-3文字ずつのチャンクに分割
      const chunks = []
      const chunkSize = 3
      for (let i = 0; i < text.length; i += chunkSize) {
        chunks.push(text.slice(i, i + chunkSize))
      }
      return chunks
    }
  }
}
