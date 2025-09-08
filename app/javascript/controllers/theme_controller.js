import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateActiveState()
  }

  setLight() {
    this.setTheme('light')
  }

  setDark() {
    this.setTheme('dark')
  }

  setTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme)
    localStorage.setItem('theme', theme)

    // Also save to cookies so Rails can access it
    this.setCookie('theme', theme, 365) // expires in 1 year
    this.updateMiradorIframes(theme)
    this.updateActiveState()
  }

  updateMiradorIframes(theme) {
    // Find all iframes that contain mirador_viewer.html in their src
    const miradorIframes = document.querySelectorAll('iframe[src*="mirador_viewer.html"]')

    miradorIframes.forEach(iframe => {
      const currentSrc = iframe.src
      const url = new URL(currentSrc)

      // Update the theme parameter
      url.searchParams.set('theme', theme)

      // Set the new src to reload the iframe with the new theme
      iframe.src = url.toString()
    })
  }

  setCookie(name, value, days) {
    let expires = ""
    if (days) {
      const date = new Date()
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000))
      expires = "; expires=" + date.toUTCString()
    }
    document.cookie = name + "=" + (value || "") + expires + "; path=/"
  }

  updateActiveState() {
    const currentTheme = document.documentElement.getAttribute('data-bs-theme')
    const buttons = this.element.querySelectorAll('[data-bs-theme-value]')

    buttons.forEach(button => {
      const buttonTheme = button.getAttribute('data-bs-theme-value')
      button.setAttribute('aria-pressed', buttonTheme === currentTheme)
    })
  }
}
