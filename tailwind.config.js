// En v4 c’est de l’ESM → on utilise export default {} au lieu de module.exports = {}
export default {
  darkMode: 'class', // active le mode sombre via la classe .dark
  content: [
    './app/views/**/*.{html,erb}',
    './app/frontend/**/*.{js,ts,vue}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
