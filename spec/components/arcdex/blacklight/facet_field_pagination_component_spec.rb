# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Blacklight::FacetFieldPaginationComponent, type: :component do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:search_state) { Blacklight::SearchState.new({ 'facet.sort' => sort }.compact, blacklight_config) }
  let(:paginator) { Blacklight::FacetPaginator.new([], sort: sort || 'release desc', limit: 20) }
  let(:presenter) do
    double('presenter', facet_field: blacklight_config.facet_fields[facet], paginator:, search_state:) # rubocop:disable RSpec/VerifiedDoubles
  end
  let(:facet) { 'set' }
  let(:sort) { nil }

  def render_buttons
    with_controller_class(CatalogController) do
      with_request_url('/catalog/facet/set') { render_inline(described_class.new(facet_field: presenter)) }
    end
  end

  it 'marks the release date sort active by default and links to the others' do
    render_buttons
    expect(page).to have_css('.sort-options span.active', text: 'Release Date Sort')
    expect(page).to have_link('A-Z Sort', href: /facet.sort=index/)
    expect(page).to have_link('Numerical Sort', href: /facet.sort=count/)
  end

  context 'when sorted A-Z' do
    let(:sort) { 'index' }

    it 'links back to the release date sort' do
      render_buttons
      expect(page).to have_css('.sort-options span.active', text: 'A-Z Sort')
      expect(page).to have_link('Release Date Sort', href: /facet.sort=release\+desc/)
    end
  end

  context 'when the facet has no json sort' do
    let(:facet) { 'rarity' }
    let(:sort) { 'count' }

    it 'shows only the A-Z and Numerical buttons' do
      render_buttons
      expect(page).to have_css('.sort-options span.active', text: 'Numerical Sort')
      expect(page).to have_link('A-Z Sort')
      expect(page).to have_no_text('Release Date Sort')
    end
  end
end
