const colors = require("tailwindcss/colors")

module.exports = {
  future: {},
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js"
  ],
  theme: {
    extend: {
      colors: {
        gray: colors.blueGray,
        teal: colors.teal
      },
      screens: {
        "bm": [
          { "raw": "(min-width: 767px) and (min-height: 777px)" },
        ],
        "bl": [
          { "raw": "(min-width: 767px) and (min-height: 915px)" },
        ]
      }
    }
  },
  variants: {},
  plugins: [],
}
