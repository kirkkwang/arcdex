import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    this.create();
  }

  create() {
    this.sortable = Sortable.create(this.element, {
      animation: 200,
      forceFallback: true,
      dataIdAttr: 'data-document-id',
      onEnd: this.onEnd.bind(this)
    })
  }

  onEnd() {
    console.log(this.sortable.toArray());
    const bookmarkOrder = this.sortable.toArray().join(',');

    fetch('/bookmarks/update_order', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ new_order: bookmarkOrder })
    }).then(response => {
      if (!response.ok) {
        console.error('Failed to update bookmark order');
      }
    }).catch(error => {
      console.error('Error updating bookmark order:', error);
    });
  }
}
