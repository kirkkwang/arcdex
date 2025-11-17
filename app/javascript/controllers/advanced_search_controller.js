import { Controller } from '@hotwired/stimulus'
import Choices from 'choices.js'

export default class extends Controller {
  static targets = [ 'clauseRow', 'filterSelect' ]

  connect() {
    this.counter = 1

    if (this.hasClauseRowTarget) {
      this.clauseRowTemplate = this.clauseRowTarget.cloneNode(true)
    }

    if (this.filterSelectTargets.length > 0) {
      this.applyChoicesJs(this.filterSelectTargets)
    }
  }

  addClauseRow() {
    const advancedSearchClausesContainer = this.element.querySelector('.advanced-search-clauses')
    const additionalClauseRow = this.clauseRowTemplate.cloneNode(true)

    return advancedSearchClausesContainer.appendChild(this.modifyClauseRow(additionalClauseRow))
  }

  modifyClauseRow(clauseRow) {
    const idx = this.counter++
    const selectElement = clauseRow.querySelector('.form-select')
    selectElement.setAttribute('name', `clause[${idx}][field]`)

    const inputElement = clauseRow.querySelector('.form-control')
    inputElement.setAttribute('name', `clause[${idx}][query]`)

    return clauseRow
  }

  removeClauseRow(event) {
    (event.target.closest('.clause-row') || event.target.closest('.filter-row')).remove()
  }

  applyChoicesJs(elements) {
    elements.forEach(element => {
      if (element.classList.contains('choices__input')) {
        return
      }

      const choices = new Choices(element, {
        removeItemButton: true,
        searchEnabled: true,
        shouldSort: false,
      })
    })
  }

  updateOperator(event) {
    const operator = event.target.value
    const filterRow = event.target.closest('.filter-row')
    const filterSelect = filterRow.querySelector('[data-advanced-search-target="filterSelect"]')
    const facetKey = filterSelect.dataset.facetKey

    if (operator === 'inclusive') {
      filterSelect.name = `f_inclusive[${facetKey}][]`
    } else {
      filterSelect.name = `f[-${facetKey}][]`
    }
  }
}
