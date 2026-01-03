// app/javascript/controllers/blog_editor_controller.js
// ブログ編集コントローラー（編集/プレビュー切り替え + Markdownレンダリング）
import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

export default class extends Controller {
  static targets = ["editTab", "previewTab", "editor", "preview", "input", "form", "newBlogForm"]
  static values = {
    debounce: { type: Number, default: 150 }
  }

  connect() {
    // markedの設定
    marked.setOptions({
      breaks: true,
      gfm: true,
      headerIds: true,
      mangle: false
    })
  }

  // 編集タブに切り替え
  showEdit() {
    this.editTabTarget.classList.add("active-tab")
    this.editTabTarget.classList.remove("inactive-tab")
    this.previewTabTarget.classList.add("inactive-tab")
    this.previewTabTarget.classList.remove("active-tab")

    this.editorTarget.classList.remove("hidden")
    this.previewTarget.classList.add("hidden")
  }

  // プレビュータブに切り替え
  showPreview() {
    this.previewTabTarget.classList.add("active-tab")
    this.previewTabTarget.classList.remove("inactive-tab")
    this.editTabTarget.classList.add("inactive-tab")
    this.editTabTarget.classList.remove("active-tab")

    this.editorTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")

    // プレビューをレンダリング
    this.renderPreview()
  }

  // Markdownをレンダリング
  renderPreview() {
    const markdown = this.inputTarget.value || ""

    if (markdown.trim() === "") {
      this.previewTarget.innerHTML = this.emptyStateHTML()
    } else {
      this.previewTarget.innerHTML = marked.parse(markdown)
    }
  }

  // 新規ブログフォームを表示/非表示
  toggleNewForm() {
    if (this.hasNewBlogFormTarget) {
      this.newBlogFormTarget.classList.toggle("hidden")
    }
  }

  // 新規ブログフォームを閉じる
  closeNewForm() {
    if (this.hasNewBlogFormTarget) {
      this.newBlogFormTarget.classList.add("hidden")
    }
  }

  // 空の状態のHTML
  emptyStateHTML() {
    return `
      <div style="text-align: center; padding: 40px 20px; color: #9ca3af;">
        <p>プレビューがここに表示されます</p>
        <p style="font-size: 12px; margin-top: 8px;">Markdown記法が使えます</p>
      </div>
    `
  }
}
