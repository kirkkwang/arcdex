# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::AdvancedSearchFormComponent, type: :component do
  let(:params) do
    ActiveSupport::HashWithIndifferentAccess.new(
      q: 'pikachu',
      search_field: 'all_fields',
      f: { 'game' => ['Pokémon TCG'], '-rarity' => ['Common'] },
      f_inclusive: { 'subtypes' => ['Future'] },
      clause: { '0' => { 'field' => 'all_fields', 'query' => 'x' } },
      op: 'must',
      sort: 'score desc',
      controller: 'catalog'
    )
  end

  let(:component) { described_class.new(response: nil, url: '/catalog', params:) }

  describe '#hidden_search_state_params' do
    subject(:hidden) { component.hidden_search_state_params }

    it 'strips the f filters so deselecting a prefilled facet removes it' do
      expect(hidden).not_to have_key(:f)
    end

    it 'strips the params the form itself resubmits' do
      expect(hidden.keys.map(&:to_s)).not_to include('f_inclusive', 'clause', 'op', 'sort')
    end

    it 'keeps unrelated params so they survive the round trip' do
      expect(hidden[:controller]).to eq('catalog')
    end

    it 'forces the gallery view' do
      expect(hidden[:view]).to eq('gallery')
    end
  end

  describe '#initial_clause_field' do
    context 'when arriving from a plain search with no clause' do
      before do
        params.delete(:clause)
        params[:search_field] = 'card_name'
      end

      it 'uses the search_field' do
        expect(component.initial_clause_field).to eq('card_name')
      end
    end

    context 'when a clause field is already present' do
      before { params[:clause] = { '0' => { 'field' => 'card_name', 'query' => 'x' } } }

      it 'prefers the clause field' do
        expect(component.initial_clause_field).to eq('card_name')
      end
    end

    context 'when nothing is present' do
      let(:params) { ActiveSupport::HashWithIndifferentAccess.new(controller: 'catalog') }

      before { allow(component).to receive(:search_fields).and_return('all_fields' => nil) }

      it 'falls back to the first search field' do
        expect(component.initial_clause_field).to eq('all_fields')
      end
    end
  end

  describe '#initial_clause_query' do
    context 'when arriving from a plain search with no clause' do
      before { params.delete(:clause) }

      it 'brings the search term over from q' do
        expect(component.initial_clause_query).to eq('pikachu')
      end
    end

    context 'when the clause query is blank but q is present' do
      before { params[:clause] = { '0' => { 'field' => 'all_fields', 'query' => '' } } }

      it 'falls back to q' do
        expect(component.initial_clause_query).to eq('pikachu')
      end
    end

    context 'when a clause query is present' do
      before { params[:clause] = { '0' => { 'field' => 'all_fields', 'query' => 'charizard' } } }

      it 'prefers the clause query' do
        expect(component.initial_clause_query).to eq('charizard')
      end
    end
  end
end
