import { Controller } from "@hotwired/stimulus"

// クリップボードからYouTube URLを自動検出するコントローラー
export default class extends Controller {
  static targets = ["input"]
  static values = {
    url: String // 既存のURL（編集時）
  }

  connect() {
    // 既存URLがある場合（編集時）は自動検出をスキップ
    if (this.urlValue && this.urlValue.length > 0) {
      return
    }
  }

  async checkClipboard() {
    // 入力欄に既に値がある場合はスキップ
    if (this.inputTarget.value && this.inputTarget.value.length > 0) {
      return
    }

    try {
      // クリップボードの読み取り権限をリクエスト
      const text = await navigator.clipboard.readText()

      // YouTube URLかどうかをチェック
      if (this.isYoutubeUrl(text)) {
        this.inputTarget.value = text.trim()
        // 入力イベントを発火してフォームバリデーションを更新
        this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
        this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      }
    } catch (error) {
      // クリップボードへのアクセスが拒否された場合は何もしない
      console.debug("クリップボードへのアクセスが拒否されました:", error)
    }
  }

  isYoutubeUrl(text) {
    if (!text) return false

    // YouTube URLパターン
    const patterns = [
      /^(https?:\/\/)?(www\.)?youtube\.com\/watch\?v=[\w-]+/,
      /^(https?:\/\/)?(www\.)?youtu\.be\/[\w-]+/,
      /^(https?:\/\/)?(www\.)?youtube\.com\/shorts\/[\w-]+/
    ]

    return patterns.some(pattern => pattern.test(text.trim()))
  }
}
