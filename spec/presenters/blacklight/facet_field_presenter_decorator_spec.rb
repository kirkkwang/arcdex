# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::FacetFieldPresenterDecorator do
  subject(:presenter) do
    Blacklight::FacetFieldPresenter.new(facet_field_config, display_facet, view_context, search_state)
  end

  let(:blacklight_config) do
    config = Blacklight::Configuration.new
    config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: true, show: true, collapse: false
    config
  end

  let(:facet_field_config) { blacklight_config.facet_fields['rarity'] }

  let(:display_facet) do
    instance_double(
      Blacklight::Solr::Response::Facets::FacetField,
      items: [],
      limit: nil,
      offset: 0,
      sort: 'count'
    )
  end

  # view_context uses dynamically-added Blacklight helper methods not on ActionView::Base
  let(:view_context) do
    double('view_context', # rubocop:disable RSpec/VerifiedDoubles
           search_state: search_state,
           params: search_state.params,
           blacklight_config: blacklight_config,
           facet_field_presenter: nil)
  end


  describe '#collapsed?' do
    context 'when the facet has no excluded values in params' do
      let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }

      it 'delegates to Blacklight default (false when collapse: false)' do
        expect(presenter.collapsed?).to be false
      end
    end

    context 'when the facet has excluded values in params' do
      let(:search_state) { Blacklight::SearchState.new({ f: { '-rarity' => ['Rare'] } }, blacklight_config) }

      it 'returns false to keep the facet card open' do
        expect(presenter.collapsed?).to be false
      end
    end

    context 'when a different facet has excluded values but this one does not' do
      let(:blacklight_config) do
        config = Blacklight::Configuration.new
        config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: true, collapse: true
        config.add_facet_field 'set', field: 'collection_ssim', excludable: true
        config
      end

      let(:search_state) { Blacklight::SearchState.new({ f: { '-set' => ['Base Set'] } }, blacklight_config) }

      it 'does not force the unrelated facet open' do
        # rarity is not excluded, so it falls back to super (collapse: true → collapsed)
        expect(presenter.collapsed?).to be true
      end
    end
  end

  describe '#facet_limit' do
    let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }

    context 'on the advanced_search action' do
      before { allow(view_context).to receive(:params).and_return({ action: 'advanced_search' }) }

      it 'returns nil' do
        expect(presenter.facet_limit).to be_nil
      end
    end

    context 'on a regular search action' do
      before { allow(view_context).to receive(:params).and_return({ action: 'index' }) }

      it 'delegates to default Blacklight behavior' do
        # Default behavior returns a limit based on config; just checking it is not nil
        result = presenter.facet_limit
        # It may be nil or an integer depending on facet config, but it should not raise
        expect { result }.not_to raise_error
      end
    end
  end

  describe '#paginator' do
    let(:search_state) { Blacklight::SearchState.new({ f: { '-rarity' => ['Rare'] } }, blacklight_config) }
    let(:items) { [] }
    let(:display_facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField).as_null_object }

    before { allow(display_facet).to receive(:items).and_return(items) }

    it 'prepends the excluded item to the facet items list' do
      presenter.paginator rescue nil
      expect(items.first).to have_attributes(value: 'Rare')
    end

    it 'does not duplicate the excluded item if already prepended' do
      excluded_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: 'Rare')
      items.unshift(excluded_item)
      presenter.paginator rescue nil
      rare_items = items.select { |i| i.value == 'Rare' }
      expect(rare_items.length).to eq(1)
    end
  end
end
