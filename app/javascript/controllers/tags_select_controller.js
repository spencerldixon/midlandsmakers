import { Controller } from "@hotwired/stimulus"
import SlimSelect from "slim-select"

// Turns the plain <select multiple> of tag names on the maker form into a
// searchable, addable picker. A Stimulus controller (rather than the plain
// document-listener approach used for basecoat/dropdown-menu) already
// connects/disconnects correctly across Turbo navigations, so no extra
// turbo:load glue is needed here.
export default class extends Controller {
  connect() {
    this.slimSelect = new SlimSelect({
      select: this.element,
      settings: {
        placeholderText: "Search or add a craft…",
        searchPlaceholder: "Search or add a craft…",
        allowDeselect: true,
      },
      events: {
        addable: (value) => value.trim().length > 0 ? value.trim() : false,
      },
    })
  }

  disconnect() {
    this.slimSelect?.destroy()
    this.slimSelect = null
  }
}
