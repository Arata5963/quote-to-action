import { Controller } from "@hotwired/stimulus"

// フラッシュメッセージの表示・非表示を制御するコントローラー
export default class extends Controller {
  static values = {
    removeAfter: { type: Number, default: 5000 }
  }

  connect() {
    // 指定時間後に自動で消える
    if (this.removeAfterValue > 0) {
      this.timeout = setTimeout(() => {
        this.remove()
      }, this.removeAfterValue)
    }
  }

  disconnect() {
    // タイムアウトをクリア
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  remove() {
    // フェードアウトアニメーション
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")

    // アニメーション完了後に要素を削除
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
