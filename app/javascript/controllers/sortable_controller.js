import { Controller } from '@hotwired/stimulus'
import { createConsumer } from "@rails/actioncable"
import Sortable from 'sortablejs'

export default class extends Controller {
  connect() {
    this.create();
    this.setupCableSubscription();
    this.isUpdating = false;
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  create() {
    this.sortable = Sortable.create(this.element, {
      animation: 200,
      forceFallback: true,
      dataIdAttr: 'data-document-id',
      handle: '.img-thumbnail',
      delay: 75,
      delayOnTouchOnly: true,
      onEnd: this.onEnd.bind(this)
    })
  }

  setupCableSubscription() {
    this.cable = createConsumer();
    this.subscription = this.cable.subscriptions.create("BookmarksChannel", {
      received: (data) => {
        if (data.action === 'order_updated') {
          this.handleRemoteOrderUpdate(data.new_order);
        }
      }
    });
  }

  handleRemoteOrderUpdate(newOrder) {
    // Set flag to prevent our own update from triggering another broadcast
    this.isUpdating = true;

    // Reorder the DOM elements to match the new order
    this.reorderElements(newOrder);

    // Reset flag after a short delay
    setTimeout(() => {
      this.isUpdating = false;
    }, 100);
  }

  reorderElements(newOrder) {
    const container = this.element;
    const elements = Array.from(container.children);

    // Create a map of document-id to element for quick lookup
    const elementMap = {};
    elements.forEach(el => {
      const docId = el.getAttribute('data-document-id');
      if (docId) {
        elementMap[docId] = el;
      }
    });

    // Reorder elements according to newOrder
    newOrder.forEach(docId => {
      const element = elementMap[docId];
      if (element) {
        container.appendChild(element); // This moves the element to the end
      }
    });
  }

  onEnd() {
    // Don't send update if this was triggered by a remote update
    if (this.isUpdating) {
      return;
    }

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
