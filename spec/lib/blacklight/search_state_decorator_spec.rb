# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::SearchStateDecorator do
  let(:blacklight_config) { Blacklight::Configuration.new }

  describe '#has_constraints?' do
    context 'with no params' do
      subject(:search_state) { Blacklight::SearchState.new({}, blacklight_config) }

      it 'returns false' do
        expect(search_state.has_constraints?).to be false
      end
    end

    context 'with a query param' do
      subject(:search_state) { Blacklight::SearchState.new({ q: 'pikachu' }, blacklight_config) }

      it 'returns true' do
        expect(search_state.has_constraints?).to be true
      end
    end

    context 'with regular filter facets' do
      subject(:search_state) { Blacklight::SearchState.new({ f: { 'rarity' => ['Rare'] } }, blacklight_config) }

      let(:blacklight_config) do
        config = Blacklight::Configuration.new
        config.add_facet_field 'rarity', field: 'rarity_ssm'
        config
      end


      it 'returns true' do
        expect(search_state.has_constraints?).to be true
      end
    end

    context 'with only exclude facets (keys starting with -)' do
      subject(:search_state) { Blacklight::SearchState.new({ f: { '-rarity' => ['Rare'] } }, blacklight_config) }

      it 'returns true even without any regular filters' do
        expect(search_state.has_constraints?).to be true
      end
    end

    context 'with only pagination params' do
      subject(:search_state) { Blacklight::SearchState.new({ per_page: 10, page: 2 }, blacklight_config) }

      it 'returns false' do
        expect(search_state.has_constraints?).to be false
      end
    end
  end
end
