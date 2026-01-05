import { Controller } from "@hotwired/stimulus"

// 「もっと見る」で追加アイテムを表示するコントローラー
export default class extends Controller {
  static targets = ["hidden", "button"]
  static values = {
    expanded: { type: Boolean, default: false }
  }

  toggle() {
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged() {
    if (this.hasHiddenTarget) {
      this.hiddenTargets.forEach(el => {
        el.style.display = this.expandedValue ? "flex" : "none"
      })
    }

    if (this.hasButtonTarget) {
      const count = this.hiddenTargets.length
      if (this.expandedValue) {
        this.buttonTarget.textContent = "閉じる ▲"
      } else {
        this.buttonTarget.textContent = `他${count}件を見る ▼`
      }
    }
  }
}
