import { Controller } from "@hotwired/stimulus"

// 折りたたみUIコントローラー
export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { open: { type: Boolean, default: true } }

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
        this.contentTarget.classList.remove("hidden")
      } else {
        this.contentTarget.classList.add("hidden")
      }
    }

    if (this.hasIconTarget) {
      if (this.openValue) {
        this.iconTarget.style.transform = "rotate(0deg)"
      } else {
        this.iconTarget.style.transform = "rotate(-90deg)"
      }
    }
  }
}
