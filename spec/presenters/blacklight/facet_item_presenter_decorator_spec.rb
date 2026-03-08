# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::FacetItemPresenterDecorator do
  subject(:presenter) do
    Blacklight::FacetItemPresenter.new(facet_item, facet_config, view_context, 'rarity', search_state)
  end

  let(:blacklight_config) do
    config = Blacklight::Configuration.new
    config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: true
    config
  end

  let(:facet_config) { blacklight_config.facet_fields['rarity'] }
  let(:facet_item) { 'Rare' }

  # view_context uses dynamically-added Blacklight helper methods not on ActionView::Base
  let(:view_context) do
    double('view_context', # rubocop:disable RSpec/VerifiedDoubles
           search_state: search_state,
           blacklight_config: blacklight_config)
  end

  describe '#classes' do
    let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }

    it 'returns an empty string' do
      expect(presenter.classes).to eq('')
    end
  end

  describe '#exclude_href' do
    let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }

    before do
      allow(search_state).to receive(:add_facet_params_and_redirect)
        .with('-rarity', facet_item)
        .and_return({ f: { '-rarity' => ['Rare'] } })
      allow(view_context).to receive(:search_action_path)
        .and_return('/catalog?f[-rarity][]=Rare')
    end

    it 'generates a path with the negated facet key' do
      expect(presenter.exclude_href).to eq('/catalog?f[-rarity][]=Rare')
    end
  end

  describe '#selected?' do
    context 'when the facet is not selected' do
      let(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }

      it 'returns falsey' do
        expect(presenter).not_to be_selected
      end
    end

    context 'when the facet is a regular selected filter' do
      let(:search_state) { Blacklight::SearchState.new({ f: { 'rarity' => ['Rare'] } }, blacklight_config) }

      it 'returns true' do
        expect(presenter.selected?).to be true
      end
    end

    context 'when the facet is an excluded filter' do
      let(:search_state) { Blacklight::SearchState.new({ f: { '-rarity' => ['Rare'] } }, blacklight_config) }

      it 'returns true for excluded facet items' do
        expect(presenter.selected?).to be true
      end
    end
  end

  describe '#remove_href' do
    context 'when the item is an excluded facet' do
      let(:search_state) { Blacklight::SearchState.new({ f: { '-rarity' => ['Rare'] } }, blacklight_config) }

      before do
        allow(view_context).to receive(:search_action_path).and_return('/catalog')
      end

      it 'generates a removal path for the exclude bucket' do
        expect { presenter.remove_href }.not_to raise_error
      end

      it 'does not call super (uses the exclude key for removal)' do
        presenter.remove_href
        expect(view_context).to have_received(:search_action_path)
      end
    end

    context 'when the item is a regular selected facet' do
      let(:search_state) { Blacklight::SearchState.new({ f: { 'rarity' => ['Rare'] } }, blacklight_config) }

      before do
        allow(view_context).to receive(:search_action_path).and_return('/catalog')
      end

      it 'delegates to default behavior' do
        expect { presenter.remove_href }.not_to raise_error
      end
    end
  end
end
