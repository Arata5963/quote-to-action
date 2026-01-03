import { Controller } from "@hotwired/stimulus"

// テキストエリア自動リサイズコントローラー
// note.com風のコメント入力欄など
export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    const textarea = this.element
    textarea.style.height = "auto"
    textarea.style.height = textarea.scrollHeight + "px"
  }
}
