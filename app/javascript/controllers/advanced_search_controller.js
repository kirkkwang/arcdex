import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [ 'clauseRow' ]

  connect() {
    this.counter = 1
    if (this.hasClauseRowTarget) {
      this.clauseRowTemplate = this.clauseRowTarget.cloneNode(true)
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
}
