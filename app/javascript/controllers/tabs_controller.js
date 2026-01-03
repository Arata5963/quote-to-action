import { Controller } from "@hotwired/stimulus"

// タブ切り替えコントローラー
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // 初期状態: 最初のタブをアクティブに
    this.showTab(0)
  }

  switch(event) {
    const index = parseInt(event.currentTarget.dataset.tabIndex, 10)
    this.showTab(index)
  }

  showTab(index) {
    // タブのスタイル更新
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        // アクティブ状態（Notion風: 黒文字 + アンダーライン）
        tab.style.color = "#111827"  // gray-900
        tab.style.borderBottom = "2px solid #111827"
      } else {
        // 非アクティブ状態（グレー、アンダーラインなし）
        tab.style.color = "#9CA3AF"  // gray-400
        tab.style.borderBottom = "2px solid transparent"
      }
    })

    // パネルの表示切り替え
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
