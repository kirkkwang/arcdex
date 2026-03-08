# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::SearchState::FilterFieldDecorator do
  let(:blacklight_config) do
    config = Blacklight::Configuration.new
    config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: true
    config
  end

  describe '#remove' do
    context 'when exclude: true' do
      let(:params) { { f: { '-rarity' => ['Rare', 'Common'] } } }
      let(:search_state) { Blacklight::SearchState.new(params, blacklight_config) }
      let(:filter_field) { search_state.filter('rarity') }

      it 'removes the value from the negated facet bucket' do
        new_state = filter_field.remove('Rare', exclude: true)
        expect(new_state.params.dig(:f, '-rarity')).not_to include('Rare')
      end

      it 'leaves other excluded values intact' do
        new_state = filter_field.remove('Rare', exclude: true)
        expect(new_state.params.dig(:f, '-rarity')).to include('Common')
      end

      it 'removes the exclude key entirely when the last excluded value is removed' do
        single_params = { f: { '-rarity' => ['Rare'] } }
        state = Blacklight::SearchState.new(single_params, blacklight_config)
        new_state = state.filter('rarity').remove('Rare', exclude: true)
        expect(new_state.params[:f]).to be_nil
      end
    end

    context 'when exclude: false (default)' do
      let(:params) { { f: { 'rarity' => ['Rare', 'Common'] } } }
      let(:search_state) { Blacklight::SearchState.new(params, blacklight_config) }
      let(:filter_field) { search_state.filter('rarity') }

      it 'removes from the regular facet key' do
        new_state = filter_field.remove('Rare')
        expect(new_state.params.dig(:f, 'rarity')).not_to include('Rare')
        expect(new_state.params.dig(:f, 'rarity')).to include('Common')
      end

      it 'does not affect the exclude facet bucket' do
        new_state = filter_field.remove('Rare')
        expect(new_state.params.dig(:f, '-rarity')).to be_nil
      end
    end
  end
end
