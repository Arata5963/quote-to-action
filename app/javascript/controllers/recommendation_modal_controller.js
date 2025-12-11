// app/javascript/controllers/recommendation_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // bodyスクロール無効化
    document.body.style.overflow = "hidden"

    // Escキーでモーダルを閉じる
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    // bodyスクロール有効化
    document.body.style.overflow = ""

    // イベントリスナー削除
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  close() {
    // 即座にモーダルを削除
    const modalContainer = document.getElementById("recommendation_modal")
    if (modalContainer) {
      modalContainer.innerHTML = ""
    }
  }

  navigate(event) {
    // リンククリック時、即座に遷移
    // デフォルト動作を許可（Turboが処理）
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
