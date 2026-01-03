import { Controller } from "@hotwired/stimulus"

// 複数エントリー一括追加フォーム
export default class extends Controller {
  static targets = ["keyPointList", "quoteList", "actionList", "template"]
  static values = { autoInit: { type: Boolean, default: false } }

  connect() {
    // autoInit が true の場合のみ、各セクションに最低1つの入力欄を表示
    if (this.autoInitValue) {
      this.ensureAtLeastOneEntry("keyPoint")
      this.ensureAtLeastOneEntry("quote")
      this.ensureAtLeastOneEntry("action")
    }
  }

  ensureAtLeastOneEntry(type) {
    const list = this[`${type}ListTarget`]
    if (list && list.children.length === 0) {
      this.addEntry({ currentTarget: { dataset: { entryType: type } }, preventDefault: () => {} })
    }
  }

  addEntry(event) {
    event.preventDefault()
    const type = event.currentTarget.dataset.entryType
    const list = this[`${type}ListTarget`]
    const index = list.children.length

    const entry = document.createElement("div")
    entry.className = "entry-item flex items-start gap-2 mb-2"
    entry.dataset.index = index

    if (type === "action") {
      entry.innerHTML = `
        <div class="flex-1 space-y-2">
          <textarea name="entries[${type}][${index}][content]"
                    placeholder="何をしますか？"
                    rows="2"
                    style="width: 100%; padding: 8px 12px; font-size: 14px; border: 1px solid #e5e7eb; border-radius: 6px; resize: vertical; min-height: 60px;"></textarea>
          <input type="date"
                 name="entries[${type}][${index}][deadline]"
                 style="width: 100%; padding: 8px 12px; font-size: 14px; border: 1px solid #e5e7eb; border-radius: 6px;">
        </div>
        <button type="button"
                data-action="multi-entry-form#removeEntry"
                style="padding: 8px; color: #9ca3af; background: none; border: none; cursor: pointer; align-self: flex-start;"
                title="削除">
          <svg style="width: 16px; height: 16px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      `
    } else {
      const placeholder = type === "keyPoint" ? "この動画の要約を入力..." : "響いたフレーズを入力..."
      const rows = type === "keyPoint" ? 2 : 3
      entry.innerHTML = `
        <textarea name="entries[${type}][${index}][content]"
                  placeholder="${placeholder}"
                  rows="${rows}"
                  class="flex-1"
                  style="width: 100%; padding: 8px 12px; font-size: 14px; border: 1px solid #e5e7eb; border-radius: 6px; resize: vertical; min-height: ${rows * 24 + 16}px;"></textarea>
        <button type="button"
                data-action="multi-entry-form#removeEntry"
                style="padding: 8px; color: #9ca3af; background: none; border: none; cursor: pointer; align-self: flex-start;"
                title="削除">
          <svg style="width: 16px; height: 16px;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      `
    }

    list.appendChild(entry)

    // 新しい入力欄にフォーカス
    const textarea = entry.querySelector("textarea")
    if (textarea) textarea.focus()
  }

  removeEntry(event) {
    event.preventDefault()
    const item = event.currentTarget.closest(".entry-item")
    if (item) {
      item.remove()
    }
  }
}
