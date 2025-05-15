import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "popup" ]

  blur(event) {
    this.popupTarget.hidden = true;
  }

  preventHide(event) {
    event.preventDefault();
  }
}
