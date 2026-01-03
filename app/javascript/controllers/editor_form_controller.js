import { Controller } from "@hotwired/stimulus"

// フルスクリーンエディタフォームコントローラー
export default class extends Controller {
  static targets = [
    "tab",
    "editor",
    "savedList",
    "keyPointEditor",
    "quoteEditor",
    "actionEditor",
    "keyPointContent",
    "quoteContent",
    "actionContent",
    "actionDeadline",
    "hiddenEntries",
    "saveButton",
    "savedCount",
    "blogTitle",
    "blogContent",
    "blogPublish"
  ]

  static values = {
    activeTab: { type: String, default: "keyPoint" }
  }

  connect() {
    this.entries = {
      keyPoint: [],
      quote: [],
      action: [],
      blog: []
    }
    this.showTab(this.activeTabValue)
    this.updateSavedList()
  }

  // タブ切り替え
  switchTab(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab
    this.showTab(tab)
  }

  showTab(tabName) {
    this.activeTabValue = tabName

    // タブのスタイル更新
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === tabName
      if (isActive) {
        tab.classList.add("editor-tab-active")
        tab.classList.remove("editor-tab-inactive")
      } else {
        tab.classList.remove("editor-tab-active")
        tab.classList.add("editor-tab-inactive")
      }
    })

    // エディタの表示切り替え（display styleを使用）
    this.editorTargets.forEach(editor => {
      const isActive = editor.dataset.editorType === tabName
      editor.style.display = isActive ? "flex" : "none"
    })

    // 対応するエディタにフォーカス
    this.focusCurrentEditor()
  }

  focusCurrentEditor() {
    setTimeout(() => {
      switch (this.activeTabValue) {
        case "keyPoint":
          if (this.hasKeyPointContentTarget) this.keyPointContentTarget.focus()
          break
        case "quote":
          if (this.hasQuoteContentTarget) this.quoteContentTarget.focus()
          break
        case "action":
          if (this.hasActionContentTarget) this.actionContentTarget.focus()
          break
        case "blog":
          if (this.hasBlogTitleTarget) this.blogTitleTarget.focus()
          break
      }
    }, 100)
  }

  // エントリーを保存
  saveEntry(event) {
    event.preventDefault()
    const type = this.activeTabValue
    let content = ""
    let deadline = null
    let title = null
    let publish = false

    switch (type) {
      case "keyPoint":
        content = this.keyPointContentTarget.value.trim()
        if (!content) return
        this.keyPointContentTarget.value = ""
        break
      case "quote":
        content = this.quoteContentTarget.value.trim()
        if (!content) return
        this.quoteContentTarget.value = ""
        break
      case "action":
        content = this.actionContentTarget.value.trim()
        deadline = this.actionDeadlineTarget.value || null
        if (!content) return
        this.actionContentTarget.value = ""
        this.actionDeadlineTarget.value = ""
        break
      case "blog":
        title = this.hasBlogTitleTarget ? this.blogTitleTarget.value.trim() : ""
        content = this.hasBlogContentTarget ? this.blogContentTarget.value.trim() : ""
        publish = this.hasBlogPublishTarget ? this.blogPublishTarget.checked : false
        if (!title && !content) return
        if (this.hasBlogTitleTarget) this.blogTitleTarget.value = ""
        if (this.hasBlogContentTarget) this.blogContentTarget.value = ""
        if (this.hasBlogPublishTarget) this.blogPublishTarget.checked = false
        break
    }

    // エントリーを追加
    const entry = {
      id: Date.now(),
      type: type,
      content: content,
      deadline: deadline,
      title: title,
      publish: publish
    }
    this.entries[type].push(entry)

    // UIを更新
    this.updateSavedList()
    this.updateHiddenFields()
    this.focusCurrentEditor()
  }

  // エントリーを削除
  removeEntry(event) {
    event.preventDefault()
    const id = parseInt(event.currentTarget.dataset.entryId)
    const type = event.currentTarget.dataset.entryType

    this.entries[type] = this.entries[type].filter(e => e.id !== id)
    this.updateSavedList()
    this.updateHiddenFields()
  }

  // 保存済みリストを更新
  updateSavedList() {
    if (!this.hasSavedListTarget) return

    const allEntries = [
      ...this.entries.keyPoint.map(e => ({ ...e, icon: "📝", label: "メモ" })),
      ...this.entries.quote.map(e => ({ ...e, icon: "💬", label: "引用" })),
      ...this.entries.action.map(e => ({ ...e, icon: "🎯", label: "アクション" })),
      ...this.entries.blog.map(e => ({ ...e, icon: "📰", label: "ブログ" }))
    ]

    const totalCount = allEntries.length

    // カウント更新
    if (this.hasSavedCountTarget) {
      this.savedCountTarget.textContent = totalCount
      this.savedCountTarget.parentElement.classList.toggle("hidden", totalCount === 0)
    }

    if (totalCount === 0) {
      this.savedListTarget.innerHTML = `
        <div class="text-center py-8 text-gray-400">
          <p>まだアウトプットがありません</p>
          <p class="text-sm mt-1">上のエディタで入力して「保存」してください</p>
        </div>
      `
      return
    }

    this.savedListTarget.innerHTML = allEntries.map(entry => `
      <div class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg group">
        <span class="text-lg flex-shrink-0">${entry.icon}</span>
        <div class="flex-1 min-w-0">
          <p class="text-sm text-gray-800 break-words" style="white-space: pre-wrap;">${this.escapeHtml(entry.content)}</p>
          ${entry.deadline ? `<p class="text-xs text-gray-500 mt-1">期日: ${entry.deadline}</p>` : ""}
        </div>
        <button type="button"
                data-action="editor-form#removeEntry"
                data-entry-id="${entry.id}"
                data-entry-type="${entry.type}"
                class="p-1 text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
                title="削除">
          <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
    `).join("")
  }

  // hidden fieldsを更新（フォーム送信用）
  updateHiddenFields() {
    if (!this.hasHiddenEntriesTarget) return

    let html = ""

    // 要約
    this.entries.keyPoint.forEach((entry, index) => {
      html += `<input type="hidden" name="entries[keyPoint][${index}][content]" value="${this.escapeHtml(entry.content)}">`
    })

    // 引用
    this.entries.quote.forEach((entry, index) => {
      html += `<input type="hidden" name="entries[quote][${index}][content]" value="${this.escapeHtml(entry.content)}">`
    })

    // アクション
    this.entries.action.forEach((entry, index) => {
      html += `<input type="hidden" name="entries[action][${index}][content]" value="${this.escapeHtml(entry.content)}">`
      if (entry.deadline) {
        html += `<input type="hidden" name="entries[action][${index}][deadline]" value="${entry.deadline}">`
      }
    })

    // ブログ（最新の1件のみ送信）
    if (this.entries.blog.length > 0) {
      const blogEntry = this.entries.blog[this.entries.blog.length - 1]
      if (blogEntry.title) {
        html += `<input type="hidden" name="blog_entry[title]" value="${this.escapeHtml(blogEntry.title)}">`
      }
      if (blogEntry.content) {
        html += `<input type="hidden" name="blog_entry[content]" value="${this.escapeHtml(blogEntry.content)}">`
      }
      if (blogEntry.publish) {
        html += `<input type="hidden" name="blog_entry[publish]" value="true">`
      }
    }

    this.hiddenEntriesTarget.innerHTML = html
  }

  // HTMLエスケープ
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  // キーボードショートカット
  handleKeydown(event) {
    // Cmd/Ctrl + Enter で保存
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault()
      this.saveEntry(event)
    }
  }
}
