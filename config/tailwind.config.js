/** @type {import('tailwindcss').Config} */
module.exports = {
    // Tailwind がクラス名を探しに行く場所（ここが超重要）
    content: [
      "./app/views/**/*.html.erb",
      "./app/helpers/**/*.rb",
      "./app/assets/**/*.erb",
      "./app/assets/**/*.css",
      "./app/javascript/**/*.{js,ts}",
    ],
    theme: {
      extend: {},   // カラーやフォントを追加したくなったらここに書く
    },
    plugins: [],    // @tailwindcss/forms 等を使うならここに追加
    // 必要に応じて:
    // darkMode: 'class',
    // prefix: 'tw-',
    // safelist: ['bg-blue-600','hover:bg-blue-700', ...],
  };