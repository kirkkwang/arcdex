# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Advanced search controller' do
  def inject_advanced_search_html
    page.execute_script(<<~JS)
      const html = `
        <div id="advanced-search-fixture" data-controller="advanced-search">
          <div class="advanced-search-clauses">
            <div class="clause-row" data-advanced-search-target="clauseRow">
              <select class="form-select" name="clause[0][field]"></select>
              <input class="form-control" name="clause[0][query]">
              <button data-action="advanced-search#removeClauseRow">Remove</button>
            </div>
          </div>
          <button id="add-advanced-search-term" data-action="advanced-search#addClauseRow">Add</button>
        </div>`;
      document.body.insertAdjacentHTML('beforeend', html);
    JS
    sleep 0.1 # wait for Stimulus to connect
  end

  before do
    visit root_path
    inject_advanced_search_html
  end

  describe 'addClauseRow' do
    it 'appends a new clause row when the add button is clicked' do
      initial_count = all('.clause-row').count
      find_by_id('add-advanced-search-term').click
      expect(all('.clause-row').count).to eq(initial_count + 1)
    end

    it 'increments the field name index on each new row' do
      find_by_id('add-advanced-search-term').click
      new_select = all('.clause-row .form-select').last
      expect(new_select['name']).to match(/clause\[1\]\[field\]/)
    end

    it 'increments the query name index on each new row' do
      find_by_id('add-advanced-search-term').click
      new_input = all('.clause-row .form-control').last
      expect(new_input['name']).to match(/clause\[1\]\[query\]/)
    end

    it 'uses a new index for each additional row' do
      find_by_id('add-advanced-search-term').click
      find_by_id('add-advanced-search-term').click
      last_select = all('.clause-row .form-select').last
      expect(last_select['name']).to match(/clause\[2\]\[field\]/)
    end
  end

  describe 'removeClauseRow' do
    it 'removes the row when the remove button is clicked' do
      initial_count = all('.clause-row').count
      find_by_id('add-advanced-search-term').click
      expect(all('.clause-row').count).to eq(initial_count + 1)

      all('[data-action="advanced-search#removeClauseRow"]').last.click
      expect(all('.clause-row').count).to eq(initial_count)
    end
  end
end
