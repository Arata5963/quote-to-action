import { Controller } from "@hotwired/stimulus"

// インラインフォーム展開/折りたたみコントローラー
export default class extends Controller {
  static targets = ["form", "toggleButton"]
  static values = {
    openText: { type: String, default: "+ 追記する" },
    closeText: { type: String, default: "× 閉じる" }
  }

  toggle() {
    if (this.hasFormTarget) {
      this.formTarget.classList.toggle("hidden")

      // ボタンのテキストを切り替え
      if (this.hasToggleButtonTarget) {
        if (this.formTarget.classList.contains("hidden")) {
          this.toggleButtonTarget.textContent = this.openTextValue
        } else {
          this.toggleButtonTarget.textContent = this.closeTextValue
        }
      }
    }
  }

  close() {
    if (this.hasFormTarget) {
      this.formTarget.classList.add("hidden")

      if (this.hasToggleButtonTarget) {
        this.toggleButtonTarget.textContent = this.openTextValue
      }
    }
  }
}
