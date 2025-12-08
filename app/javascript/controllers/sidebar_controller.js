import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]

  connect() {
    // ESCキーで閉じる
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  open() {
    // サイドバーを開く
    this.panelTarget.classList.remove("translate-x-full")
    this.panelTarget.classList.add("translate-x-0")

    // オーバーレイを表示
    this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
    this.overlayTarget.classList.add("opacity-100", "pointer-events-auto")

    // bodyのスクロールを無効化
    document.body.classList.add("overflow-hidden")
  }

  close() {
    // サイドバーを閉じる
    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.add("translate-x-full")

    // オーバーレイを非表示
    this.overlayTarget.classList.remove("opacity-100", "pointer-events-auto")
    this.overlayTarget.classList.add("opacity-0", "pointer-events-none")

    // bodyのスクロールを有効化
    document.body.classList.remove("overflow-hidden")
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
