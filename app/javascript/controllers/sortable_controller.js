import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    const sortable = Sortable.create(this.element, {
      animation: 200,
      forceFallback: true
    })
  }
}
