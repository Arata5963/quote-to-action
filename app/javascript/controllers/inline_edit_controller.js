import { Controller } from "@hotwired/stimulus"

// インライン編集コントローラー
export default class extends Controller {
  static targets = ["display", "form", "input"]

  toggle() {
    this.displayTarget.classList.toggle("hidden")
    this.formTarget.classList.toggle("hidden")

    // フォーム表示時にフォーカス
    if (!this.formTarget.classList.contains("hidden") && this.hasInputTarget) {
      this.inputTarget.focus()
    }
  }

  cancel() {
    this.displayTarget.classList.remove("hidden")
    this.formTarget.classList.add("hidden")
  }
}
