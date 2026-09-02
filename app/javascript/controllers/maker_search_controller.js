import { Controller } from "@hotwired/stimulus"

// Submits the search form after the visitor pauses typing. Turbo targets the
// results frame, while the form still works as a normal GET form without JS.
// The clear controls are JS-driven because the header lives outside the frame
// that Turbo replaces, so their state can only be kept in sync client-side.
export default class extends Controller {
  static targets = ["clear", "query", "reset", "resetAll"]

  static values = {
    delay: { type: Number, default: 250 }
  }

  connect() {
    this.sync()
  }

  search() {
    window.clearTimeout(this.timeout)
    this.sync()
    this.timeout = window.setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  clearTags(event) {
    event.preventDefault()
    this.uncheckTags()
    this.sync()
    this.element.requestSubmit()
  }

  clearQuery(event) {
    event.preventDefault()
    if (!this.hasQueryTarget) return

    this.queryTarget.value = ""
    this.queryTarget.focus()
    this.sync()
    this.element.requestSubmit()
  }

  clearAll(event) {
    event.preventDefault()
    this.uncheckTags()
    if (this.hasQueryTarget) this.queryTarget.value = ""
    this.sync()
    this.element.requestSubmit()
  }

  submit() {
    window.clearTimeout(this.timeout)
  }

  disconnect() {
    window.clearTimeout(this.timeout)
  }

  sync() {
    const hasTags = Boolean(this.element.querySelector("input[name='tags[]']:checked"))
    const hasQuery = this.hasQueryTarget && this.queryTarget.value.trim().length > 0

    if (this.hasClearTarget) this.clearTarget.hidden = !hasTags
    if (this.hasResetTarget) this.resetTarget.hidden = !hasQuery
    if (this.hasResetAllTarget) this.resetAllTarget.hidden = !(hasTags || hasQuery)
  }

  uncheckTags() {
    this.element.querySelectorAll("input[name='tags[]']").forEach((input) => {
      input.checked = false
    })
  }
}
