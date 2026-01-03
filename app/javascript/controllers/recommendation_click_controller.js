// app/javascript/controllers/recommendation_click_controller.js
// 布教クリックを追跡するコントローラー
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  track(event) {
    // クリックを追跡（非同期で送信、リンク遷移は止めない）
    if (this.hasUrlValue) {
      fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
          "Accept": "application/json"
        },
        credentials: "same-origin"
      }).catch(() => {
        // エラーは無視（ユーザー体験に影響しない）
      })
    }
    // デフォルトのリンク動作は継続（YouTubeに遷移）
  }
}
