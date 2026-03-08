# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::ExcludeFacetItemPresenter do
  subject(:presenter) do
    described_class.new(facet_item, facet_config, view_context, '-rarity', search_state)
  end

  let(:exclude_class) { 'text-decoration-line-through' }

  let(:blacklight_config) do
    config = Blacklight::Configuration.new
    config.index.constraints_component_exclude_styling = exclude_class
    config.add_facet_field 'rarity', field: 'rarity_ssm', excludable: true
    config
  end

  let(:facet_config) { blacklight_config.facet_fields['rarity'] }
  let(:facet_item) { 'Rare' }
  let(:search_state) { Blacklight::SearchState.new({ f: { '-rarity' => ['Rare'] } }, blacklight_config) }

  # view_context uses dynamically-added Blacklight helper methods not on ActionView::Base
  let(:view_context) do
    double('view_context', # rubocop:disable RSpec/VerifiedDoubles
           search_state: search_state,
           blacklight_config: blacklight_config)
  end


  describe '#classes' do
    it 'returns the configured exclude styling class from blacklight config' do
      expect(presenter.classes).to eq(exclude_class)
    end
  end

  it 'inherits from Blacklight::FacetItemPresenter' do
    expect(described_class.ancestors).to include(Blacklight::FacetItemPresenter)
  end
end
