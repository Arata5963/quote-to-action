// app/javascript/controllers/youtube_search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "urlField", "searchPanel", "urlPanel", "urlTab", "searchTab", "preview", "thumbnail", "title", "channel"]
  static values = {
    url: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.timeout = null
    // 既存のURLがあればプレビューを表示
    if (this.hasUrlFieldTarget && this.urlFieldTarget.value) {
      this.fetchVideoInfo()
    }
  }

  toggleMode(event) {
    const mode = event.currentTarget.dataset.mode
    if (mode === "search") {
      this.searchPanelTarget.classList.remove("hidden")
      this.urlPanelTarget.classList.add("hidden")
      // タブのスタイル更新
      if (this.hasSearchTabTarget && this.hasUrlTabTarget) {
        this.searchTabTarget.classList.add("active")
        this.urlTabTarget.classList.remove("active")
      }
    } else {
      this.searchPanelTarget.classList.add("hidden")
      this.urlPanelTarget.classList.remove("hidden")
      // タブのスタイル更新
      if (this.hasSearchTabTarget && this.hasUrlTabTarget) {
        this.urlTabTarget.classList.add("active")
        this.searchTabTarget.classList.remove("active")
      }
    }
  }

  // URL入力時に動画情報を取得
  async fetchVideoInfo() {
    if (!this.hasUrlFieldTarget) return

    const url = this.urlFieldTarget.value.trim()
    if (!url) {
      this.hidePreview()
      return
    }

    // YouTube URLからビデオIDを抽出
    const videoId = this.extractVideoId(url)
    if (!videoId) {
      this.hidePreview()
      return
    }

    // サムネイルプレビューを表示（API呼び出し前に）
    if (this.hasPreviewTarget && this.hasThumbnailTarget) {
      this.thumbnailTarget.src = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`
      this.previewTarget.classList.remove("hidden")

      // タイトルとチャンネル名はまだ取得中
      if (this.hasTitleTarget) this.titleTarget.textContent = "読み込み中..."
      if (this.hasChannelTarget) this.channelTarget.textContent = ""
    }
  }

  extractVideoId(url) {
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
      /^([a-zA-Z0-9_-]{11})$/
    ]

    for (const pattern of patterns) {
      const match = url.match(pattern)
      if (match) return match[1]
    }
    return null
  }

  hidePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("hidden")
    }
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()

    if (query.length < this.minLengthValue) {
      this.hideResults()
      return
    }

    this.timeout = setTimeout(() => {
      this.fetchResults(query)
    }, 300)
  }

  async fetchResults(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error("Search failed")

      const videos = await response.json()
      this.renderResults(videos)
    } catch (error) {
      console.error("YouTube search error:", error)
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 py-4">検索に失敗しました</p>'
      this.showResults()
    }
  }

  renderResults(videos) {
    if (videos.length === 0) {
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 py-4">動画が見つかりません</p>'
      this.showResults()
      return
    }

    const html = videos.map(video => `
      <button type="button"
              class="w-full flex items-start gap-3 p-3 hover:bg-gray-50 rounded-lg transition-colors text-left"
              data-action="click->youtube-search#selectVideo"
              data-url="${video.youtube_url}"
              data-title="${this.escapeHtml(video.title)}"
              data-channel="${this.escapeHtml(video.channel_name)}">
        <img src="${video.thumbnail_url}" alt="" class="w-24 h-14 object-cover rounded flex-shrink-0">
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 line-clamp-2">${this.escapeHtml(video.title)}</p>
          <p class="text-xs text-gray-500 mt-0.5">${this.escapeHtml(video.channel_name)}</p>
        </div>
      </button>
    `).join("")

    this.resultsTarget.innerHTML = html
    this.showResults()
  }

  selectVideo(event) {
    const button = event.currentTarget
    const url = button.dataset.url
    const title = button.dataset.title
    const channel = button.dataset.channel
    const thumbnail = button.querySelector("img")?.src

    // URL入力フィールドに設定
    this.urlFieldTarget.value = url

    // URL入力モードに切り替え
    this.searchPanelTarget.classList.add("hidden")
    this.urlPanelTarget.classList.remove("hidden")

    // タブのスタイル更新
    if (this.hasSearchTabTarget && this.hasUrlTabTarget) {
      this.urlTabTarget.classList.add("active")
      this.searchTabTarget.classList.remove("active")
    }

    // プレビューを更新
    if (this.hasPreviewTarget) {
      if (this.hasThumbnailTarget && thumbnail) {
        this.thumbnailTarget.src = thumbnail
      }
      if (this.hasTitleTarget) {
        this.titleTarget.textContent = title || ""
      }
      if (this.hasChannelTarget) {
        this.channelTarget.textContent = channel || ""
      }
      this.previewTarget.classList.remove("hidden")
    }

    // 検索結果をクリア
    this.inputTarget.value = ""
    this.hideResults()

    // URLフィールドのinputイベントを発火（YouTube情報取得のため）
    this.urlFieldTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
  }

  showResults() {
    this.resultsTarget.classList.remove("hidden")
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  // クリック外で結果を閉じる
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}
