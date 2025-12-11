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
        // アクティブ状態
        tab.style.color = "#8B7355"  // accent color
        tab.style.borderBottom = "2px solid #8B7355"
      } else {
        // 非アクティブ状態
        tab.style.color = "rgba(74, 64, 53, 0.6)"  // primary/60
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
