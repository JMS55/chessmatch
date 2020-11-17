module.exports = {
  future: {
    // removeDeprecatedGapUtilities: true,
    // purgeLayersByDefault: true,
  },
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js"
  ],
  theme: {
    extend: {
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
