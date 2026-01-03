import { Controller } from "@hotwired/stimulus"

// アウトプットタブ切り替えコントローラー
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { activeTab: { type: String, default: "keyPoint" } }

  connect() {
    this.showTab(this.activeTabValue)
  }

  switch(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab
    this.showTab(tab)
  }

  showTab(tabName) {
    // タブのスタイル更新
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === tabName
      if (isActive) {
        tab.classList.add("active-tab")
        tab.classList.remove("inactive-tab")
      } else {
        tab.classList.remove("active-tab")
        tab.classList.add("inactive-tab")
      }
    })

    // パネルの表示切り替え
    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.panel === tabName
      panel.classList.toggle("hidden", !isActive)
    })

    this.activeTabValue = tabName
  }
}
