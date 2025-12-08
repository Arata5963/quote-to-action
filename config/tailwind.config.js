/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/assets/**/*.erb",
    "./app/assets/**/*.css",
    "./app/javascript/**/*.{js,ts}",
  ],
  theme: {
    extend: {
      colors: {
        // ウォームベージュ系カラーパレット
        cream: '#FAF8F5',
        primary: '#4A4035',
        accent: '#8B7355',
      },
      fontFamily: {
        sans: ['Inter', 'Noto Sans JP', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        'card': '1rem',
        'button': '0.75rem',
      },
      boxShadow: {
        'card': '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        'card-hover': '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
};