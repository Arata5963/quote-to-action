import { Controller } from "@hotwired/stimulus"

// 全体/自分トグルスイッチコントローラー
export default class extends Controller {
  static targets = ["switch", "labelAll", "labelMine"]
  static values = {
    scope: { type: String, default: "" },
    formId: { type: String, default: "search_form" }
  }

  connect() {
    this.updateUI()
  }

  toggle() {
    // 現在のスコープを切り替え
    this.scopeValue = this.scopeValue === "mine" ? "" : "mine"

    // フォームを送信
    this.submitForm()
  }

  scopeValueChanged() {
    this.updateUI()
  }

  updateUI() {
    const isMine = this.scopeValue === "mine"

    // スイッチの位置を更新
    if (this.hasSwitchTarget) {
      if (isMine) {
        this.switchTarget.classList.add("translate-x-full")
      } else {
        this.switchTarget.classList.remove("translate-x-full")
      }
    }

    // ラベルの強調表示を更新
    if (this.hasLabelAllTarget) {
      if (isMine) {
        this.labelAllTarget.classList.remove("text-primary", "font-medium")
        this.labelAllTarget.classList.add("text-primary/50")
      } else {
        this.labelAllTarget.classList.add("text-primary", "font-medium")
        this.labelAllTarget.classList.remove("text-primary/50")
      }
    }

    if (this.hasLabelMineTarget) {
      if (isMine) {
        this.labelMineTarget.classList.add("text-primary", "font-medium")
        this.labelMineTarget.classList.remove("text-primary/50")
      } else {
        this.labelMineTarget.classList.remove("text-primary", "font-medium")
        this.labelMineTarget.classList.add("text-primary/50")
      }
    }
  }

  submitForm() {
    const form = document.getElementById(this.formIdValue)
    if (form) {
      // hidden input を更新
      let hiddenInput = form.querySelector('input[name="tab"]')
      if (!hiddenInput) {
        hiddenInput = document.createElement("input")
        hiddenInput.type = "hidden"
        hiddenInput.name = "tab"
        form.appendChild(hiddenInput)
      }
      hiddenInput.value = this.scopeValue

      form.submit()
    }
  }
}
