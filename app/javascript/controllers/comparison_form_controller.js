import { Controller } from "@hotwired/stimulus"

// 比較フォームの表示/非表示切り替え
export default class extends Controller {
  static targets = ["form", "toggleButton"]

  toggle() {
    this.formTarget.classList.toggle("hidden")
    this.toggleButtonTarget.classList.toggle("hidden")
  }
}
