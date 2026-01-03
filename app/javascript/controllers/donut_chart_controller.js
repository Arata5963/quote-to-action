import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    values: Array,
    labels: Array,
    colors: Array
  }

  connect() {
    // Chart.jsがロードされるまで待機
    this.initChart()
  }

  initChart() {
    if (typeof Chart === "undefined") {
      setTimeout(() => this.initChart(), 100)
      return
    }

    const canvas = this.element.querySelector("canvas")
    if (!canvas) return

    const ctx = canvas.getContext("2d")
    const values = this.valuesValue
    const labels = this.labelsValue
    const colors = this.colorsValue

    // すべて0の場合はグレーの円を表示
    const total = values.reduce((a, b) => a + b, 0)

    if (total === 0) {
      new Chart(ctx, {
        type: "doughnut",
        data: {
          labels: ["データなし"],
          datasets: [{
            data: [1],
            backgroundColor: ["#e5e7eb"],
            borderWidth: 0
          }]
        },
        options: {
          cutout: "60%",
          plugins: {
            legend: { display: false },
            tooltip: { enabled: false }
          }
        }
      })
      return
    }

    new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: labels,
        datasets: [{
          data: values,
          backgroundColor: colors,
          borderWidth: 0,
          hoverOffset: 4
        }]
      },
      options: {
        cutout: "60%",
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const label = context.label || ""
                const value = context.parsed || 0
                const percentage = Math.round((value / total) * 100)
                return `${label}: ${value}件 (${percentage}%)`
              }
            }
          }
        }
      }
    })
  }
}
