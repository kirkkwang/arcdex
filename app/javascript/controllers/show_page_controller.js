import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const hasAnchor = window.location.hash

    if (hasAnchor) {
      setTimeout(() => {
        window.location.href = window.location.href
      }, 200)
    }
  }
}
