import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["documents", "pagination", "loadingIndicator"]
  static values = {
    url: String,
    currentPage: Number,
    totalPages: Number,
    loading: Boolean,
    documentCount: Number
  }

  connect() {
    this.loadingValue = false

    // Find the actual #documents div inside our element and set it as our target
    this.actualDocumentsContainer = this.element.querySelector('#documents')

    // Get the total count from the page entries info
    const pageEntriesSpan = document.querySelector('.page-entries strong:last-child')
    if (pageEntriesSpan) {
      this.totalItems = parseInt(pageEntriesSpan.textContent, 10)
    }

    // Initialize current document count from page entries info
    const currentEntriesSpan = document.querySelector('.page-entries strong:nth-child(2)')
    if (currentEntriesSpan) {
      this.documentCountValue = parseInt(currentEntriesSpan.textContent, 10)
    } else {
      // Fallback to counting DOM elements
      this.documentCountValue = this.actualDocumentsContainer ? this.actualDocumentsContainer.children.length : 0
    }

    this.setupInfiniteScroll()
  }

  disconnect() {
    this.removeScrollListener()
  }

  setupInfiniteScroll() {
    // Create and bind the scroll handler
    this.scrollHandler = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.scrollHandler)

    // Hide the original pagination
    if (this.hasPaginationTarget) {
      this.paginationTarget.style.display = 'none'
    }

    // Create loading indicator if it doesn't exist
    this.createLoadingIndicator()
  }

  removeScrollListener() {
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler)
    }
  }

  createLoadingIndicator() {
    if (!this.hasLoadingIndicatorTarget) {
      const loadingDiv = document.createElement('div')
      loadingDiv.innerHTML = `
        <div class="text-center p-4" data-infinite-scroll-target="loadingIndicator" style="display: none;">
          <div class="spinner-border" role="status">
            <span class="visually-hidden">Loading more results...</span>
          </div>
          <p class="mt-2">Loading more results...</p>
        </div>
      `
      this.element.appendChild(loadingDiv.firstElementChild)
    }
  }

  handleScroll() {
    // Don't load if we're already loading or at the last page
    if (this.loadingValue || this.currentPageValue >= this.totalPagesValue) {
      return
    }

    // Check if we're near the bottom of the page
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop
    const windowHeight = window.innerHeight
    const documentHeight = document.documentElement.scrollHeight

    // Trigger when we're 200px from the bottom
    if (scrollTop + windowHeight >= documentHeight - 200) {
      this.loadNextPage()
    }
  }

  async loadNextPage() {
    if (this.loadingValue) return

    this.loadingValue = true
    this.showLoadingIndicator()

    try {
      const nextPage = this.currentPageValue + 1
      const url = new URL(this.urlValue, window.location.origin)

      // Add pagination and infinite scroll parameters
      url.searchParams.set('page', nextPage)
      url.searchParams.set('infinite_scroll', 'true')

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      // Get number of new documents from the response data if available
      let newDocumentCount = 0
      if (data.pagination && data.pagination.limit) {
        newDocumentCount = data.pagination.limit
      }

      // Append new documents to the existing list
      this.appendDocuments(data.documents_html, newDocumentCount)

      // Update pagination info
      this.currentPageValue = data.pagination.current_page
      this.totalPagesValue = data.pagination.total_pages

    } catch (error) {
      console.error('Error loading more results:', error)
      this.showError()
    } finally {
      this.loadingValue = false
      this.hideLoadingIndicator()
    }
  }

  updatePageEntriesCount() {
    // Update the entries display with the correct count
    const pageEntriesInfoElement = document.querySelector('.page-entries')
    if (pageEntriesInfoElement) {
      const firstEntrySpan = pageEntriesInfoElement.querySelector('strong:first-child')
      const currentEntriesSpan = pageEntriesInfoElement.querySelector('strong:nth-child(2)')
      const totalEntriesSpan = pageEntriesInfoElement.querySelector('strong:last-child')

      if (firstEntrySpan && currentEntriesSpan && totalEntriesSpan) {
        // Keep first entry as 1
        // Update current entries to match our count
        currentEntriesSpan.textContent = this.documentCountValue.toString()
        // Ensure total doesn't change
      }
    }
  }

  appendDocuments(documentsHtml, expectedCount) {
    // Use the actual #documents container we found in connect()
    if (this.actualDocumentsContainer) {
      // Create a temporary container to parse the HTML
      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = documentsHtml

      // Find the documents container in the returned HTML and extract its children
      const newDocumentsContainer = tempDiv.querySelector('#documents')
      let addedCount = 0

      if (newDocumentsContainer) {
        // Count document elements in the new container
        const documentElements = newDocumentsContainer.querySelectorAll('.document')
        addedCount = documentElements.length

        // Move each child from the new container to the existing one
        while (newDocumentsContainer.firstChild) {
          this.actualDocumentsContainer.appendChild(newDocumentsContainer.firstChild)
        }
      } else {
        // Fallback: if no #documents container found, append all content
        // and count document elements
        const documentElements = tempDiv.querySelectorAll('.document')
        addedCount = documentElements.length

        while (tempDiv.firstChild) {
          this.actualDocumentsContainer.appendChild(tempDiv.firstChild)
        }
      }

      // If we got an expected count from the API, use that
      // Otherwise use the actual number of elements we counted
      const countToAdd = expectedCount || addedCount

      // Don't exceed the total items count
      if (this.totalItems && this.documentCountValue + countToAdd > this.totalItems) {
        this.documentCountValue = this.totalItems
      } else {
        this.documentCountValue += countToAdd
      }

      // Update the page entries display
      this.updatePageEntriesCount()
    }
  }  showLoadingIndicator() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.style.display = 'block'
    }
  }

  hideLoadingIndicator() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.style.display = 'none'
    }
  }

  showError() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.innerHTML = `
        <div class="alert alert-warning text-center">
          <p>Unable to load more results. Please try refreshing the page.</p>
        </div>
      `
    }
  }
}
