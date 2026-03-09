# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::AdvancedSearchFilterComponent do
  subject { component }

  let(:component) { described_class.new(facet_field:) }
  let(:facet_field_config) { double('facet_field_config', excludable: true) } # rubocop:disable RSpec/VerifiedDoubles
  let(:item) { double('item', value: 'Rare', label: 'Rare') } # rubocop:disable RSpec/VerifiedDoubles
  let(:display_facet) { double('display_facet', items: [item]) } # rubocop:disable RSpec/VerifiedDoubles
  let(:facet_field) do
    double('facet_field', # rubocop:disable RSpec/VerifiedDoubles
           key: 'rarity',
           label: 'Rarity',
           facet_field: facet_field_config,
           display_facet:)
  end

  describe '#facet_field_id' do
    it 'prefixes the key with advanced_search_' do
      expect(component.facet_field_id).to eq('advanced_search_rarity')
    end
  end

  describe '#excludable?' do
    it 'delegates to the facet field config' do
      expect(component.excludable?).to be true
    end

    it 'returns false when facet field is not excludable' do
      allow(facet_field_config).to receive(:excludable).and_return(false)
      expect(component.excludable?).to be false
    end
  end

  describe '#facet_options' do
    it 'builds an option tag for each display facet item' do
      result = component.facet_options
      expect(result).to include('Rare')
      expect(result).to include('<option')
    end
  end

  describe '#facet_field_label' do
    it 'uses the translation with the field key, falling back to the field label' do
      allow(component).to receive(:t).and_return('Rarity')
      expect(component.facet_field_label).to eq('Rarity')
    end
  end
end
