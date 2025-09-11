import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "overlay", "zoomImage"]

  connect() {
    // Bind event handlers
    this.escapeHandler = this.handleEscape.bind(this)
    this.popstateHandler = this.handlePopstate.bind(this)
    this.keydownHandler = this.handleKeydown.bind(this)
    this.touchStartHandler = this.handleTouchStart.bind(this)
    this.touchEndHandler = this.handleTouchEnd.bind(this)
    this.isZoomOpen = false
    this.currentIndex = 0
    this.imageElements = []
    this.touchStartX = 0
    this.touchStartY = 0
  }

  open(event) {
    const triggerImage = event.currentTarget

    // Get all image elements on the page
    this.imageElements = Array.from(document.querySelectorAll('[data-zoomed-image-url]'))

    // Find the current image index
    this.currentIndex = this.imageElements.findIndex(img => img === triggerImage)

    // Set the zoomed image source and alt
    this.updateZoomedImage(triggerImage)

    // Hide navigation if only one image
    if (this.imageElements.length <= 1) {
      this.overlayTarget.dataset.singleImage = "true"
    } else {
      this.overlayTarget.dataset.singleImage = "false"
    }

    // Add a history entry for the zoom state
    history.pushState({ imageZoomOpen: true }, '', window.location.href)
    this.isZoomOpen = true

    // Prevent body scroll
    document.body.classList.add('zoom-active')

    // Show overlay with animation
    this.overlayTarget.classList.add('active')

    // Add event listeners
    document.addEventListener('keydown', this.escapeHandler)
    document.addEventListener('keydown', this.keydownHandler)
    this.overlayTarget.addEventListener('touchstart', this.touchStartHandler, { passive: true })
    this.overlayTarget.addEventListener('touchend', this.touchEndHandler, { passive: true })
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
    document.removeEventListener('keydown', this.keydownHandler)
    this.overlayTarget.removeEventListener('touchstart', this.touchStartHandler)
    this.overlayTarget.removeEventListener('touchend', this.touchEndHandler)
    window.removeEventListener('popstate', this.popstateHandler)

    this.isZoomOpen = false

    // Go back in history if we're still on the zoom state
    if (history.state && history.state.imageZoomOpen) {
      history.back()
    }
  }

  nextImage() {
    if (!this.isZoomOpen || this.imageElements.length === 0) return

    this.currentIndex = (this.currentIndex + 1) % this.imageElements.length
    this.updateZoomedImage(this.imageElements[this.currentIndex])
  }

  previousImage() {
    if (!this.isZoomOpen || this.imageElements.length === 0) return

    this.currentIndex = this.currentIndex === 0 ? this.imageElements.length - 1 : this.currentIndex - 1
    this.updateZoomedImage(this.imageElements[this.currentIndex])
  }

  updateZoomedImage(imageElement) {
    this.zoomImageTarget.src = imageElement.dataset.zoomedImageUrl
    this.zoomImageTarget.alt = imageElement.alt
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
    document.removeEventListener('keydown', this.keydownHandler)
    this.overlayTarget.removeEventListener('touchstart', this.touchStartHandler)
    this.overlayTarget.removeEventListener('touchend', this.touchEndHandler)
    window.removeEventListener('popstate', this.popstateHandler)
    this.isZoomOpen = false
  }

  handleEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  handleKeydown(event) {
    if (!this.isZoomOpen) return

    switch(event.key) {
      case 'ArrowRight':
      case 'ArrowDown':
        event.preventDefault()
        this.nextImage()
        break
      case 'ArrowLeft':
      case 'ArrowUp':
        event.preventDefault()
        this.previousImage()
        break
    }
  }

  handleTouchStart(event) {
    this.touchStartX = event.touches[0].clientX
    this.touchStartY = event.touches[0].clientY
  }

  handleTouchEnd(event) {
    if (!this.touchStartX || !this.touchStartY) return

    const touchEndX = event.changedTouches[0].clientX
    const touchEndY = event.changedTouches[0].clientY
    const deltaX = this.touchStartX - touchEndX
    const deltaY = this.touchStartY - touchEndY

    const minSwipeDistance = 50 // minimum distance for a swipe

    // Horizontal swipes
    if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > minSwipeDistance) {
      if (deltaX > 0) {
        // Swipe left -> next image
        this.nextImage()
      } else {
        // Swipe right -> previous image
        this.previousImage()
      }
    }
    // Vertical swipes
    else if (Math.abs(deltaY) > minSwipeDistance) {
      if (deltaY > 0) {
        // Swipe up -> next image
        this.nextImage()
      } else {
        // Swipe down -> previous image
        this.previousImage()
      }
    }

    // Reset touch coordinates
    this.touchStartX = 0
    this.touchStartY = 0
  }

  disconnect() {
    // Cleanup when controller is removed
    document.removeEventListener('keydown', this.escapeHandler)
    document.removeEventListener('keydown', this.keydownHandler)
    if (this.overlayTarget) {
      this.overlayTarget.removeEventListener('touchstart', this.touchStartHandler)
      this.overlayTarget.removeEventListener('touchend', this.touchEndHandler)
    }
    window.removeEventListener('popstate', this.popstateHandler)
    document.body.classList.remove('zoom-active')
    this.isZoomOpen = false
  }
}
