import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('close', this.handleClose.bind(this));
  }

  handleClose() {
    // Restore body scrolling when modal closes natively
    document.body.style.overflow = '';
    document.body.style.paddingRight = '';
  }
}
