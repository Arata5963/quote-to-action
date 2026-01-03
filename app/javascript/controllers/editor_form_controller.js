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
    "blogPublish",
    // 布教
    "recommendationLevel",
    "recommendationPoint",
    "recommendationAudience",
    // 比較
    "comparisonSearch",
    "comparisonResults",
    "comparisonSelected",
    "comparisonSelectedItem",
    "comparisonReason"
  ]

  static values = {
    activeTab: { type: String, default: "keyPoint" },
    searchUrl: { type: String, default: "/posts/search_for_comparison" }
  }

  connect() {
    this.entries = {
      keyPoint: [],
      quote: [],
      action: [],
      blog: [],
      recommendation: null,  // 布教は1件のみ
      comparison: []         // 比較は複数可
    }
    this.selectedComparisonPost = null
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
        case "recommendation":
          if (this.hasRecommendationPointTarget) this.recommendationPointTarget.focus()
          break
        case "comparison":
          if (this.hasComparisonSearchTarget) this.comparisonSearchTarget.focus()
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
      case "recommendation":
        this.saveRecommendation()
        return
      case "comparison":
        this.saveComparison()
        return
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

  // 布教を保存
  saveRecommendation() {
    const level = this.hasRecommendationLevelTarget ? parseInt(this.recommendationLevelTarget.value) : null
    const point = this.hasRecommendationPointTarget ? this.recommendationPointTarget.value.trim() : ""
    const audience = this.hasRecommendationAudienceTarget ? this.recommendationAudienceTarget.value.trim() : ""

    if (!level || !point) {
      alert("おすすめ度とおすすめポイントは必須です")
      return
    }

    // 布教は1件のみ（上書き）
    this.entries.recommendation = {
      id: Date.now(),
      type: "recommendation",
      level: level,
      point: point,
      audience: audience
    }

    // フォームをクリア
    if (this.hasRecommendationLevelTarget) this.recommendationLevelTarget.value = ""
    if (this.hasRecommendationPointTarget) this.recommendationPointTarget.value = ""
    if (this.hasRecommendationAudienceTarget) this.recommendationAudienceTarget.value = ""
    // 星をリセット
    this.element.querySelectorAll('[data-controller="rating"] button').forEach(btn => {
      btn.classList.remove("text-orange-500")
      btn.classList.add("text-gray-300")
    })

    this.updateSavedList()
    this.updateHiddenFields()
  }

  // 比較を保存
  saveComparison() {
    if (!this.selectedComparisonPost) {
      alert("比較する動画を選択してください")
      return
    }

    const reason = this.hasComparisonReasonTarget ? this.comparisonReasonTarget.value.trim() : ""

    // 既に同じ投稿が比較対象に存在するかチェック
    const exists = this.entries.comparison.find(c => c.targetPostId === this.selectedComparisonPost.id)
    if (exists) {
      alert("この動画は既に比較対象に追加されています")
      return
    }

    this.entries.comparison.push({
      id: Date.now(),
      type: "comparison",
      targetPostId: this.selectedComparisonPost.id,
      targetPostTitle: this.selectedComparisonPost.title,
      targetPostThumbnail: this.selectedComparisonPost.thumbnail,
      reason: reason
    })

    // フォームをクリア
    this.selectedComparisonPost = null
    if (this.hasComparisonSearchTarget) this.comparisonSearchTarget.value = ""
    if (this.hasComparisonReasonTarget) this.comparisonReasonTarget.value = ""
    if (this.hasComparisonSelectedTarget) this.comparisonSelectedTarget.classList.add("hidden")
    if (this.hasComparisonSelectedItemTarget) this.comparisonSelectedItemTarget.innerHTML = ""

    this.updateSavedList()
    this.updateHiddenFields()
  }

  // 比較対象を検索
  async searchComparison(event) {
    const query = event.target.value.trim()
    if (query.length < 2) {
      if (this.hasComparisonResultsTarget) this.comparisonResultsTarget.classList.add("hidden")
      return
    }

    try {
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`)
      const posts = await response.json()

      if (posts.length === 0) {
        if (this.hasComparisonResultsTarget) {
          this.comparisonResultsTarget.innerHTML = '<div class="p-3 text-sm text-gray-500">検索結果がありません</div>'
          this.comparisonResultsTarget.classList.remove("hidden")
        }
        return
      }

      if (this.hasComparisonResultsTarget) {
        this.comparisonResultsTarget.innerHTML = posts.map(post => `
          <div class="flex items-center gap-3 p-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0"
               data-action="click->editor-form#selectComparison"
               data-post-id="${post.id}"
               data-post-title="${this.escapeHtml(post.title)}"
               data-post-thumbnail="${post.thumbnail}">
            <img src="${post.thumbnail}" alt="" class="w-16 h-9 object-cover rounded">
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">${this.escapeHtml(post.title)}</p>
              <p class="text-xs text-gray-500">${this.escapeHtml(post.channel)}</p>
            </div>
          </div>
        `).join("")
        this.comparisonResultsTarget.classList.remove("hidden")
      }
    } catch (error) {
      console.error("Comparison search error:", error)
    }
  }

  // 比較対象を選択
  selectComparison(event) {
    const postId = parseInt(event.currentTarget.dataset.postId)
    const postTitle = event.currentTarget.dataset.postTitle
    const postThumbnail = event.currentTarget.dataset.postThumbnail

    this.selectedComparisonPost = {
      id: postId,
      title: postTitle,
      thumbnail: postThumbnail
    }

    // 検索結果を非表示
    if (this.hasComparisonResultsTarget) this.comparisonResultsTarget.classList.add("hidden")
    if (this.hasComparisonSearchTarget) this.comparisonSearchTarget.value = ""

    // 選択済み表示
    if (this.hasComparisonSelectedTarget && this.hasComparisonSelectedItemTarget) {
      this.comparisonSelectedItemTarget.innerHTML = `
        <img src="${postThumbnail}" alt="" class="w-16 h-9 object-cover rounded flex-shrink-0">
        <p class="text-sm font-medium text-gray-900 flex-1 min-w-0 truncate">${this.escapeHtml(postTitle)}</p>
        <button type="button" data-action="click->editor-form#clearComparison" class="text-gray-400 hover:text-red-500">
          <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      `
      this.comparisonSelectedTarget.classList.remove("hidden")
    }
  }

  // 選択済み比較対象をクリア
  clearComparison(event) {
    event.preventDefault()
    this.selectedComparisonPost = null
    if (this.hasComparisonSelectedTarget) this.comparisonSelectedTarget.classList.add("hidden")
    if (this.hasComparisonSelectedItemTarget) this.comparisonSelectedItemTarget.innerHTML = ""
  }

  // エントリーを削除
  removeEntry(event) {
    event.preventDefault()
    const id = parseInt(event.currentTarget.dataset.entryId)
    const type = event.currentTarget.dataset.entryType

    if (type === "recommendation") {
      this.entries.recommendation = null
    } else if (type === "comparison") {
      this.entries.comparison = this.entries.comparison.filter(e => e.id !== id)
    } else {
      this.entries[type] = this.entries[type].filter(e => e.id !== id)
    }
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
      ...this.entries.blog.map(e => ({ ...e, icon: "📰", label: "ブログ" })),
      ...(this.entries.recommendation ? [{ ...this.entries.recommendation, icon: "📣", label: "布教" }] : []),
      ...this.entries.comparison.map(e => ({ ...e, icon: "⚖️", label: "比較" }))
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

    this.savedListTarget.innerHTML = allEntries.map(entry => {
      // 布教の表示
      if (entry.type === "recommendation") {
        return `
          <div class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg group">
            <span class="text-lg flex-shrink-0">${entry.icon}</span>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-1 mb-1">
                ${'🔥'.repeat(entry.level)}
              </div>
              <p class="text-sm text-gray-800 break-words" style="white-space: pre-wrap;">${this.escapeHtml(entry.point)}</p>
              ${entry.audience ? `<p class="text-xs text-gray-500 mt-1">対象: ${this.escapeHtml(entry.audience)}</p>` : ""}
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
        `
      }
      // 比較の表示
      if (entry.type === "comparison") {
        return `
          <div class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg group">
            <span class="text-lg flex-shrink-0">${entry.icon}</span>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <img src="${entry.targetPostThumbnail}" alt="" class="w-12 h-7 object-cover rounded">
                <span class="text-sm font-medium text-gray-800 truncate">${this.escapeHtml(entry.targetPostTitle)}</span>
              </div>
              ${entry.reason ? `<p class="text-xs text-gray-500">${this.escapeHtml(entry.reason)}</p>` : ""}
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
        `
      }
      // 通常のエントリー表示
      return `
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
      `
    }).join("")
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

    // 布教（1件のみ）
    if (this.entries.recommendation) {
      html += `<input type="hidden" name="recommendation[level]" value="${this.entries.recommendation.level}">`
      html += `<input type="hidden" name="recommendation[point]" value="${this.escapeHtml(this.entries.recommendation.point)}">`
      if (this.entries.recommendation.audience) {
        html += `<input type="hidden" name="recommendation[audience]" value="${this.escapeHtml(this.entries.recommendation.audience)}">`
      }
    }

    // 比較（複数可）
    this.entries.comparison.forEach((entry, index) => {
      html += `<input type="hidden" name="comparisons[${index}][target_post_id]" value="${entry.targetPostId}">`
      if (entry.reason) {
        html += `<input type="hidden" name="comparisons[${index}][reason]" value="${this.escapeHtml(entry.reason)}">`
      }
    })

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
