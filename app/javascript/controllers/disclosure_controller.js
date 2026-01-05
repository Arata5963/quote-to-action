import { Controller } from "@hotwired/stimulus"

// アコーディオン/開閉トグルコントローラー
export default class extends Controller {
  static targets = ["content", "icon"]
  static values = {
    open: { type: Boolean, default: false }
  }

  connect() {
    this.updateUI()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.updateUI()
  }

  updateUI() {
    if (this.hasContentTarget) {
      if (this.openValue) {
        this.contentTarget.style.display = "block"
      } else {
        this.contentTarget.style.display = "none"
      }
    }

    if (this.hasIconTarget) {
      if (this.openValue) {
        this.iconTarget.style.transform = "rotate(180deg)"
      } else {
        this.iconTarget.style.transform = "rotate(0deg)"
      }
    }
  }
}
