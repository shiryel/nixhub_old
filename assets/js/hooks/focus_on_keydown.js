FocusOnKeydown = {
  mounted() {
    window.addEventListener("keyup", e => {
      if (document.activeElement !== this.el && event.key === "s") {
        this.el.focus()
      }
      if (document.activeElement !== this.el && event.key === "S") {
        this.el.value = ""
        this.el.focus()
      }
    })

    window.addEventListener("keydown", e => {
      if (document.activeElement == this.el && event.key == "Enter") {
        this.el.blur()
        //this.pushEvent("search", this.el.value)
      }
    })
  }
}

export default FocusOnKeydown
