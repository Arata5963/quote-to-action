// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

// 無限スクロールコントローラー
export default class extends Controller {
  static targets = ["entries", "pagination", "loader"]
  static values = {
    url: String,
    page: { type: Number, default: 1 },
    loading: { type: Boolean, default: false },
    hasMore: { type: Boolean, default: true }
  }

  connect() {
    this.createObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  createObserver() {
    const options = {
      root: null,
      rootMargin: "200px", // 200px手前で読み込み開始
      threshold: 0
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.loadMore()
        }
      })
    }, options)

    // ローダー要素を監視
    if (this.hasLoaderTarget) {
      this.observer.observe(this.loaderTarget)
    }
  }

  async loadMore() {
    // 既に読み込み中、または次ページがない場合はスキップ
    if (this.loadingValue || !this.hasMoreValue) return

    this.loadingValue = true
    this.pageValue++

    try {
      // URLにページ番号を追加
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("page", this.pageValue)

      const response = await fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html"
        }
      })

      if (response.ok) {
        const html = await response.text()

        // Turbo Streamレスポンスを処理
        if (html.includes("turbo-stream")) {
          Turbo.renderStreamMessage(html)
        } else {
          // 通常のHTMLの場合（フォールバック）
          const parser = new DOMParser()
          const doc = parser.parseFromString(html, "text/html")
          const newEntries = doc.querySelectorAll("[data-infinite-scroll-entry]")

          if (newEntries.length === 0) {
            this.hasMoreValue = false
            this.hideLoader()
          } else {
            newEntries.forEach(entry => {
              this.entriesTarget.appendChild(entry.cloneNode(true))
            })
          }
        }
      }
    } catch (error) {
      console.error("Infinite scroll error:", error)
    } finally {
      this.loadingValue = false
    }
  }

  // Turbo Streamから呼び出される（次ページがない場合）
  noMoreResults() {
    this.hasMoreValue = false
    this.hideLoader()
  }

  hideLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.style.display = "none"
    }
  }

  // ページやタブが変わったときにリセット
  reset() {
    this.pageValue = 1
    this.hasMoreValue = true
    this.loadingValue = false
    if (this.hasLoaderTarget) {
      this.loaderTarget.style.display = ""
    }
  }
}
