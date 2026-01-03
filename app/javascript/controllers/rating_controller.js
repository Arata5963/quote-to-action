// app/javascript/controllers/rating_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "star", "button"]
  static values = { value: { type: Number, default: 0 } }

  connect() {
    // 初期値を設定
    if (this.hasInputTarget && this.valueValue > 0) {
      this.inputTarget.value = this.valueValue
    }
    this.updateDisplay()
  }

  select(event) {
    // data-rating, data-level または data-rating-level-param から値を取得
    const rating = parseInt(event.currentTarget.dataset.rating || event.currentTarget.dataset.level || event.params?.level)
    if (this.hasInputTarget) {
      this.inputTarget.value = rating
    }
    this.updateDisplay()
  }

  hover(event) {
    const rating = parseInt(event.currentTarget.dataset.rating || event.currentTarget.dataset.level || event.params?.level)
    this.highlightStars(rating)
  }

  leave() {
    this.updateDisplay()
  }

  updateDisplay() {
    const currentRating = this.hasInputTarget ? (parseInt(this.inputTarget.value) || 0) : 0
    this.highlightStars(currentRating)
  }

  highlightStars(count) {
    // star targets（従来の星評価用）
    this.starTargets.forEach((star, index) => {
      if (index < count) {
        star.classList.add("text-yellow-400")
        star.classList.remove("text-gray-300")
      } else {
        star.classList.remove("text-yellow-400")
        star.classList.add("text-gray-300")
      }
    })

    // button targets（布教の🔥評価用）
    this.buttonTargets.forEach((button) => {
      const level = parseInt(button.dataset.level)
      if (level <= count) {
        button.style.opacity = "1"
      } else {
        button.style.opacity = "0.3"
      }
    })
  }
}
