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

    this.updateActiveState()
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
