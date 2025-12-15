module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        obsidian: '#050505',
        carbon: '#111111',
        steel: '#333333',
        ash: '#888888',
        acid: {
          lime: '#CCFF00',
          cyan: '#00FFFF',
          pink: '#FF0099',
          purple: '#BD00FF',
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        mono: ['Space Mono', 'monospace'],
      },
      backgroundImage: {
        'grid-pattern': "linear-gradient(to right, #333 1px, transparent 1px), linear-gradient(to bottom, #333 1px, transparent 1px)",
      }
    },
  },
  plugins: [],
}
