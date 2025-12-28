// app/javascript/controllers/video_slider_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "indicator", "prevBtn", "nextBtn", "info"]
  static values = { total: Number }

  connect() {
    this.currentIndex = 0
    this.updateButtons()
    console.log("video-slider connected", {
      slides: this.slideTargets.length,
      total: this.totalValue
    })
  }

  next() {
    console.log("next clicked", { current: this.currentIndex, total: this.totalValue })
    if (this.currentIndex < this.totalValue - 1) {
      this.goToSlide(this.currentIndex + 1)
    }
  }

  prev() {
    console.log("prev clicked", { current: this.currentIndex })
    if (this.currentIndex > 0) {
      this.goToSlide(this.currentIndex - 1)
    }
  }

  goTo(event) {
    const index = parseInt(event.currentTarget.dataset.slideIndex)
    this.goToSlide(index)
  }

  goToSlide(index) {
    // 現在のスライドを非表示
    if (this.slideTargets[this.currentIndex]) {
      this.slideTargets[this.currentIndex].classList.add("hidden")
    }
    if (this.hasInfoTarget && this.infoTargets[this.currentIndex]) {
      this.infoTargets[this.currentIndex].classList.add("hidden")
    }
    if (this.hasIndicatorTarget && this.indicatorTargets[this.currentIndex]) {
      this.indicatorTargets[this.currentIndex].classList.remove("bg-accent")
      this.indicatorTargets[this.currentIndex].classList.add("bg-primary/20")
    }

    // 新しいスライドを表示
    this.currentIndex = index
    if (this.slideTargets[this.currentIndex]) {
      this.slideTargets[this.currentIndex].classList.remove("hidden")
    }
    if (this.hasInfoTarget && this.infoTargets[this.currentIndex]) {
      this.infoTargets[this.currentIndex].classList.remove("hidden")
    }
    if (this.hasIndicatorTarget && this.indicatorTargets[this.currentIndex]) {
      this.indicatorTargets[this.currentIndex].classList.add("bg-accent")
      this.indicatorTargets[this.currentIndex].classList.remove("bg-primary/20")
    }

    this.updateButtons()
  }

  updateButtons() {
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.disabled = this.currentIndex === 0
    }
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.disabled = this.currentIndex === this.totalValue - 1
    }
  }
}
