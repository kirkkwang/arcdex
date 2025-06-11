import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "overlay", "zoomImage"]

  connect() {
    // Bind event handlers
    this.escapeHandler = this.handleEscape.bind(this)
    this.popstateHandler = this.handlePopstate.bind(this)
    this.isZoomOpen = false
  }

  open(event) {
    const triggerImage = event.currentTarget

    // Set the zoomed image source and alt
    this.zoomImageTarget.src = triggerImage.dataset.zoomedImageUrl
    this.zoomImageTarget.alt = triggerImage.alt

    // Add a history entry for the zoom state
    history.pushState({ imageZoomOpen: true }, '', window.location.href)
    this.isZoomOpen = true

    // Prevent body scroll
    document.body.classList.add('zoom-active')

    // Show overlay with animation
    this.overlayTarget.classList.add('active')

    // Add event listeners
    document.addEventListener('keydown', this.escapeHandler)
    window.addEventListener('popstate', this.popstateHandler)
  }

  close() {
    if (!this.isZoomOpen) return

    // Remove active class
    this.overlayTarget.classList.remove('active')

    // Re-enable body scroll
    document.body.classList.remove('zoom-active')

    // Remove event listeners
    document.removeEventListener('keydown', this.escapeHandler)
    window.removeEventListener('popstate', this.popstateHandler)

    this.isZoomOpen = false

    // Go back in history if we're still on the zoom state
    if (history.state && history.state.imageZoomOpen) {
      history.back()
    }
  }

  preventClose(event) {
    // Prevent click on image from closing overlay
    event.stopPropagation()
  }

  handlePopstate(event) {
    // If user hits back button while zoom is open, close the zoom
    if (this.isZoomOpen) {
      this.closeWithoutHistory()
    }
  }

  closeWithoutHistory() {
    // Close zoom without manipulating history (since back button already did that)
    this.overlayTarget.classList.remove('active')
    document.body.classList.remove('zoom-active')
    document.removeEventListener('keydown', this.escapeHandler)
    window.removeEventListener('popstate', this.popstateHandler)
    this.isZoomOpen = false
  }

  handleEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  disconnect() {
    // Cleanup when controller is removed
    document.removeEventListener('keydown', this.escapeHandler)
    window.removeEventListener('popstate', this.popstateHandler)
    document.body.classList.remove('zoom-active')
    this.isZoomOpen = false
  }
}
