import { Controller } from "@hotwired/stimulus"

// アウトプット種類選択コントローラー
// key_point, quote, action の3種類に応じてフォームフィールドを表示/非表示
export default class extends Controller {
  static targets = ["typeRadio", "keyPointFields", "quoteFields", "actionFields", "keyPointContent", "quoteContent", "actionContent", "actionDeadline"]

  connect() {
    this.updateFields()
  }

  changeType() {
    this.updateFields()
  }

  updateFields() {
    const selectedType = this.getSelectedType()

    // すべてのフィールドを非表示に
    this.hideAllFields()

    // 選択されたタイプに応じてフィールドを表示
    switch (selectedType) {
      case "key_point":
        this.showKeyPointFields()
        break
      case "quote":
        this.showQuoteFields()
        break
      case "action":
        this.showActionFields()
        break
    }
  }

  getSelectedType() {
    const checkedRadio = this.typeRadioTargets.find(radio => radio.checked)
    return checkedRadio ? checkedRadio.value : "action" // デフォルトは action
  }

  hideAllFields() {
    if (this.hasKeyPointFieldsTarget) {
      this.keyPointFieldsTarget.classList.add("hidden")
      if (this.hasKeyPointContentTarget) {
        this.keyPointContentTarget.removeAttribute("required")
        this.keyPointContentTarget.disabled = true
      }
    }

    if (this.hasQuoteFieldsTarget) {
      this.quoteFieldsTarget.classList.add("hidden")
      if (this.hasQuoteContentTarget) {
        this.quoteContentTarget.removeAttribute("required")
        this.quoteContentTarget.disabled = true
      }
    }

    if (this.hasActionFieldsTarget) {
      this.actionFieldsTarget.classList.add("hidden")
      if (this.hasActionContentTarget) {
        this.actionContentTarget.removeAttribute("required")
        this.actionContentTarget.disabled = true
      }
      if (this.hasActionDeadlineTarget) {
        this.actionDeadlineTarget.removeAttribute("required")
        this.actionDeadlineTarget.disabled = true
      }
    }
  }

  showKeyPointFields() {
    if (this.hasKeyPointFieldsTarget) {
      this.keyPointFieldsTarget.classList.remove("hidden")
      if (this.hasKeyPointContentTarget) {
        this.keyPointContentTarget.setAttribute("required", "required")
        this.keyPointContentTarget.disabled = false
      }
    }
  }

  showQuoteFields() {
    if (this.hasQuoteFieldsTarget) {
      this.quoteFieldsTarget.classList.remove("hidden")
      if (this.hasQuoteContentTarget) {
        this.quoteContentTarget.setAttribute("required", "required")
        this.quoteContentTarget.disabled = false
      }
    }
  }

  showActionFields() {
    if (this.hasActionFieldsTarget) {
      this.actionFieldsTarget.classList.remove("hidden")
      if (this.hasActionContentTarget) {
        this.actionContentTarget.setAttribute("required", "required")
        this.actionContentTarget.disabled = false
      }
      if (this.hasActionDeadlineTarget) {
        this.actionDeadlineTarget.setAttribute("required", "required")
        this.actionDeadlineTarget.disabled = false
      }
    }
  }
}
