// app/javascript/controllers/file_preview_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "label", "status", "area", "preview", "defaultIcon", "existingImage"]

  handleFileSelect() {
    const file = this.inputTarget.files[0]
    
    if (file && file.type.startsWith('image/')) {
      // ファイルを読み込んでプレビュー表示
      const reader = new FileReader()
      reader.onload = (e) => {
        this.showNewPreview(e.target.result)
      }
      reader.readAsDataURL(file)
      
      // UI状態を更新
      this.updateUI()
    }
  }

  showNewPreview(imageSrc) {
    // 既存画像を非表示
    if (this.hasExistingImageTarget) {
      this.existingImageTarget.classList.add("hidden")
    }

    // デフォルトアイコンを非表示
    if (this.hasDefaultIconTarget) {
      this.defaultIconTarget.classList.add("hidden")
    }

    // 新しいプレビュー画像を設定・表示
    this.previewTarget.src = imageSrc
    this.previewTarget.classList.remove("hidden")
  }

  updateUI() {
    // ラベルテキストを変更
    this.labelTarget.textContent = "別のファイルを選択"
    
    // ステータス表示を表示
    this.statusTarget.classList.remove("hidden")
    
    // エリアの色を変更
    this.areaTarget.classList.remove("border-gray-300")
    this.areaTarget.classList.add("border-green-400", "bg-green-50")
  }
}