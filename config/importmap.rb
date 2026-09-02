# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Vendored from node_modules/basecoat-css/dist/js — the CSS-only basecoat-css
# import gives us the markup/classes (dropdown-menu, popover, etc.) but none
# of the JS that actually drives them; basecoat.js must load first, it's what
# every other component registers itself against.
pin "basecoat", to: "basecoat.min.js", preload: true
pin "basecoat/dropdown-menu", to: "dropdown-menu.min.js", preload: true

# Vendored from node_modules/slim-select/dist/slimselect.es.js (self-contained
# ES module, no further imports of its own) — the searchable/addable tag
# picker on the maker form. See app/javascript/controllers/tags_select_controller.js.
pin "slim-select", to: "slimselect.js"
