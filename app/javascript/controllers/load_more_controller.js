// app/javascript/controllers/load_more_controller.js
// 画面がいっぱいになるまで自動読み込み、その後「もっと見る」ボタンを表示
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "container"]

  connect() {
    this.isLoading = false
    this.checkAndLoad()
    this.resizeHandler = this.checkAndLoad.bind(this)
    window.addEventListener("resize", this.resizeHandler)

    // DOM変更を監視（Turbo Stream対応）
    this.observer = new MutationObserver(() => {
      setTimeout(() => {
        this.isLoading = false
        this.checkAndLoad()
      }, 100)
    })

    if (this.hasContainerTarget) {
      this.observer.observe(this.containerTarget, { childList: true, subtree: true })
    }
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeHandler)
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  // ターゲットが動的に追加された時
  buttonTargetConnected() {
    this.checkAndLoad()
  }

  checkAndLoad() {
    if (!this.hasButtonTarget || !this.hasContainerTarget) return

    const container = this.containerTarget
    const button = this.buttonTarget

    // ボタン内にリンクがあるかチェック（次ページがあるか）
    const loadMoreLink = button.querySelector("a")
    if (!loadMoreLink) {
      // 次ページがない場合はボタンを非表示のまま
      button.classList.add("hidden")
      return
    }

    // コンテナの底がビューポートの底より下にあるかチェック
    const containerRect = container.getBoundingClientRect()
    const viewportHeight = window.innerHeight

    // フッターの高さを考慮（約80px）
    const footerHeight = 80
    const availableHeight = viewportHeight - footerHeight

    // コンテンツが画面に収まりきらない場合（スクロールが必要な場合）
    const needsScroll = containerRect.bottom > availableHeight

    if (needsScroll) {
      // 画面いっぱい → ボタンを表示
      button.classList.remove("hidden")
    } else {
      // 画面に余裕あり → 自動で次を読み込み
      button.classList.add("hidden")
      if (!this.isLoading) {
        this.isLoading = true
        loadMoreLink.click()
      }
    }
  }
}
