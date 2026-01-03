// app/javascript/controllers/markdown_preview_controller.js
// Markdownリアルタイムプレビューコントローラー
import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

export default class extends Controller {
  static targets = ["input", "preview"]
  static values = {
    debounce: { type: Number, default: 150 }
  }

  connect() {
    // markedの設定
    marked.setOptions({
      breaks: true,        // 改行を<br>に変換
      gfm: true,           // GitHub Flavored Markdown
      headerIds: true,     // 見出しにIDを付与
      mangle: false        // メールアドレスを変換しない
    })

    // 初期プレビュー
    this.render()
  }

  // 入力時にプレビューを更新（debounce付き）
  update() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.render()
    }, this.debounceValue)
  }

  // Markdownをレンダリング
  render() {
    const markdown = this.inputTarget.value || ""

    if (markdown.trim() === "") {
      this.previewTarget.innerHTML = this.emptyStateHTML()
    } else {
      this.previewTarget.innerHTML = marked.parse(markdown)
    }
  }

  // 空の状態のHTML
  emptyStateHTML() {
    return `
      <div class="markdown-empty">
        <p>プレビューがここに表示されます</p>
        <p class="markdown-empty-hint">Markdown記法が使えます</p>
      </div>
    `
  }
}
