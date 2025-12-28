import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

// 日本語ロケール定義
const Japanese = {
  weekdays: {
    shorthand: ["日", "月", "火", "水", "木", "金", "土"],
    longhand: ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
  },
  months: {
    shorthand: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
    longhand: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
  },
  firstDayOfWeek: 0,
  rangeSeparator: " から ",
  weekAbbreviation: "週",
  scrollTitle: "スクロールして変更",
  toggleTitle: "クリックして切り替え",
  time_24hr: true
}

// Flatpickrによる日時ピッカーコントローラー
export default class extends Controller {
  static targets = ["input"]
  static values = {
    enableTime: { type: Boolean, default: true },
    minDate: { type: String, default: "today" },
    dateFormat: { type: String, default: "Y-m-d H:i" }
  }

  connect() {
    this.initFlatpickr()
  }

  disconnect() {
    if (this.flatpickrInstance) {
      this.flatpickrInstance.destroy()
    }
  }

  initFlatpickr() {
    const inputElement = this.hasInputTarget ? this.inputTarget : this.element

    this.flatpickrInstance = flatpickr(inputElement, {
      locale: Japanese,
      enableTime: this.enableTimeValue,
      time_24hr: true,
      minDate: this.minDateValue,
      dateFormat: this.dateFormatValue,
      disableMobile: true,
      onChange: (selectedDates, dateStr) => {
        // Turbo対応: changeイベントを発火
        inputElement.dispatchEvent(new Event("change", { bubbles: true }))
      }
    })
  }
}
