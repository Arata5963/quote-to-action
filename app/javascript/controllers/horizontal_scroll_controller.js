// app/javascript/controllers/horizontal_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "leftBtn", "rightBtn", "leftFade", "rightFade"]

  connect() {
    // 初期状態でボタンの表示を更新
    this.updateNavigation()
  }

  scrollRight() {
    if (this.hasContainerTarget) {
      const cardWidth = 172 // カード幅160px + gap12px
      this.containerTarget.scrollBy({
        left: cardWidth * 2,
        behavior: "smooth"
      })
    }
  }

  scrollLeft() {
    if (this.hasContainerTarget) {
      const cardWidth = 172
      this.containerTarget.scrollBy({
        left: -cardWidth * 2,
        behavior: "smooth"
      })
    }
  }

  onScroll() {
    this.updateNavigation()
  }

  updateNavigation() {
    if (!this.hasContainerTarget) return

    const container = this.containerTarget
    const scrollLeft = container.scrollLeft
    const scrollWidth = container.scrollWidth
    const clientWidth = container.clientWidth
    const maxScroll = scrollWidth - clientWidth

    const canScrollLeft = scrollLeft > 10
    const canScrollRight = scrollLeft < maxScroll - 10

    // 左ボタン
    if (this.hasLeftBtnTarget) {
      this.leftBtnTarget.classList.toggle("hidden", !canScrollLeft)
    }

    // 右ボタン
    if (this.hasRightBtnTarget) {
      this.rightBtnTarget.classList.toggle("hidden", !canScrollRight)
    }

    // 左フェード
    if (this.hasLeftFadeTarget) {
      this.leftFadeTarget.classList.toggle("hidden", !canScrollLeft)
    }

    // 右フェード
    if (this.hasRightFadeTarget) {
      this.rightFadeTarget.classList.toggle("hidden", !canScrollRight)
    }
  }
}
