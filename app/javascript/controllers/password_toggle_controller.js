import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "iconShow", "iconHide"]

  connect() {
    this.hidePassword()
  }

  toggle() {
    if (this.inputTarget.type === "password") {
      this.showPassword()
    } else {
      this.hidePassword()
    }
  }

  showPassword() {
    this.inputTarget.type = "text"
    this.iconShowTarget.classList.add("hidden")
    this.iconHideTarget.classList.remove("hidden")
  }

  hidePassword() {
    this.inputTarget.type = "password"
    this.iconShowTarget.classList.remove("hidden")
    this.iconHideTarget.classList.add("hidden")
  }
}
