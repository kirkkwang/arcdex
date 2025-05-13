import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Restore scroll position when controller connects
    this.restoreScrollPosition()

    // Select all internal links (same domain)
    const allLinks = document.querySelectorAll(`a[href^="/"]:not([target="_blank"]), a[href^="${window.location.origin}"]:not([target="_blank"])`)

    // Add event listeners to all links
    allLinks.forEach(link => {
      // Avoid adding multiple listeners to the same link
      if (!link.hasScrollPositionHandler) {
        link.addEventListener('click', this.storeScrollPosition.bind(this))
        link.hasScrollPositionHandler = true
      }
    })
  }

  storeScrollPosition(event) {
    // Only store position for navigation within the same site
    const link = event.currentTarget
    const targetUrl = new URL(link.href, window.location.origin)
    const currentUrl = new URL(window.location.href)

    // Skip if it's an anchor link in the same page
    if (targetUrl.pathname === currentUrl.pathname && targetUrl.hash) {
      return
    }

    // Store current scroll position in sessionStorage
    sessionStorage.setItem('arclight-scroll-position', window.scrollY)
  }

  restoreScrollPosition() {
    // Check if we have a stored position
    const storedPosition = sessionStorage.getItem('arclight-scroll-position')

    if (storedPosition) {
      // Use requestAnimationFrame to ensure the DOM is fully loaded and rendered
      requestAnimationFrame(() => {
        window.scrollTo({
          top: parseInt(storedPosition),
          behavior: 'auto'
        })

        // Clear the stored position after using it
        sessionStorage.removeItem('arclight-scroll-position')
      })
    }
  }
}
