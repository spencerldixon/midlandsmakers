// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Order matters: basecoat.js sets up the registry every other basecoat/*
// component registers itself into on load.
import "basecoat"
import "basecoat/dropdown-menu"

// basecoat.js only wires itself up on the browser's DOMContentLoaded, which
// fires once — Turbo Drive swaps in every later page without one. Its
// MutationObserver doesn't save us either: Turbo replaces document.body
// outright, so the observer (bound to the old body reference at that one
// DOMContentLoaded) is left watching a detached node and never sees
// anything on the new page. Redo both on every Turbo visit: initAll() picks
// up components already in the new body, and restarting the observer binds
// it to the body that's actually live now, so components added afterwards
// (e.g. by a Turbo Frame/Stream update) keep working too.
document.addEventListener("turbo:load", () => {
  window.basecoat.stop()
  window.basecoat.start()
  window.basecoat.initAll()
})
