import { Controller } from "@hotwired/stimulus"

// 長いテキストの「続きを読む」トグルコントローラー
export default class extends Controller {
  static targets = ["content", "button"]
  static values = {
    expanded: { type: Boolean, default: false },
    maxLines: { type: Number, default: 4 }
  }

  connect() {
    // DOMが完全にレンダリングされた後にチェック
    requestAnimationFrame(() => {
      this.checkTruncation()
    })
  }

  checkTruncation() {
    if (!this.hasContentTarget || !this.hasButtonTarget) return

    const content = this.contentTarget
    // scrollHeight > clientHeight なら切り詰められている
    const isTruncated = content.scrollHeight > content.clientHeight

    if (isTruncated) {
      this.buttonTarget.style.display = "inline-flex"
    } else {
      this.buttonTarget.style.display = "none"
    }
  }

  toggle() {
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged() {
    if (!this.hasContentTarget || !this.hasButtonTarget) return

    if (this.expandedValue) {
      // 展開
      this.contentTarget.classList.remove(`line-clamp-${this.maxLinesValue}`)
      this.buttonTarget.textContent = "閉じる ▲"
    } else {
      // 折りたたみ
      this.contentTarget.classList.add(`line-clamp-${this.maxLinesValue}`)
      this.buttonTarget.textContent = "続きを読む ▼"
    }
  }
}
