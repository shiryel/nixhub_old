/*******************************
* Scroll to top when searching *
********************************/
window.addEventListener("search", (event) => {
  window.scrollTo(0, 0)
});

/*******************************
* Dark / Light theme selection *
********************************/
let ls = window.localStorage

if (ls.theme === 'dark' || (!('theme' in ls) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
  document.documentElement.classList.add('dark')
} else {
  document.documentElement.classList.remove('dark')
}

window.addEventListener("toggle_dark_mode", (event) => {
  if (ls.theme === 'dark' || (!('theme' in ls) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    ls.theme = 'light'
    document.documentElement.classList.remove('dark')
  } else {
    ls.theme = 'dark'
    document.documentElement.classList.add('dark')
  }
});
