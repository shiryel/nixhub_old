// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")

module.exports = {
  darkMode: 'class',
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        version: "#FD4F00",
        // https://draculatheme.com/contribute
        bg: "#282a36",
        bg_focus: "#44475a",
        fg: "#f8f8f2",
        comment: "#6272a4",
        cyan: "#8be9fd",
        green: "#50fa7b",
        //orange: "#ffb86c",
        pink: "#ff79c6",
        purple: "#bd93f9",
        red: "#ff5555",
        yellow: "#f1fa8c"
      },
      fontFamily: {
        'code': ["Monaco","Menlo","Consolas","Courier New","monospace"]
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"]))
  ]
}
