# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::AdvancedSearchFilterComponent do
  subject { component }

  let(:component) { described_class.new(facet_field:) }
  let(:facet_field_config) { double('facet_field_config', excludable: true) } # rubocop:disable RSpec/VerifiedDoubles
  let(:item) { double('item', value: 'Rare', label: 'Rare') } # rubocop:disable RSpec/VerifiedDoubles
  let(:display_facet) { double('display_facet', items: [item]) } # rubocop:disable RSpec/VerifiedDoubles
  let(:filter) { double('filter', values: []) } # rubocop:disable RSpec/VerifiedDoubles
  let(:params) { ActiveSupport::HashWithIndifferentAccess.new }
  let(:search_state) { double('search_state', filter:, params:) } # rubocop:disable RSpec/VerifiedDoubles
  let(:facet_field) do
    double('facet_field', # rubocop:disable RSpec/VerifiedDoubles
           key: 'rarity',
           label: 'Rarity',
           facet_field: facet_field_config,
           display_facet:,
           search_state:)
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

    it 'does not mark options selected when nothing is in the params' do
      expect(component.facet_options).not_to include('selected')
    end

    it 'marks an option selected when its value is an inclusive filter' do
      allow(filter).to receive(:values).and_return(['Rare'])
      expect(component.facet_options).to include('selected')
    end

    it 'renders an option for a selected value missing from the displayed items' do
      allow(filter).to receive(:values).and_return(['Ultra Rare'])
      result = component.facet_options
      expect(result).to include('Ultra Rare')
      expect(result).to include('selected')
    end
  end

  describe '#selected_values' do
    it 'returns the inclusive filter values from f and f_inclusive' do
      allow(filter).to receive(:values).and_return(['Rare'])
      expect(component.selected_values).to eq(['Rare'])
    end

    it 'returns the excluded values when only excludes are present' do
      params[:f] = { '-rarity' => ['Common'] }
      expect(component.selected_values).to eq(['Common'])
    end

    it 'ignores the missing-facet sentinel in the excluded values' do
      params[:f] = { '-rarity' => [Arcdex::AdvancedSearchFilterComponent::MISSING_PARAM] }
      expect(component.selected_values).to eq([])
    end
  end

  describe '#excluded?' do
    it 'is false when there are no filters' do
      expect(component.excluded?).to be false
    end

    it 'is true when only excluded values are present' do
      params[:f] = { '-rarity' => ['Common'] }
      expect(component.excluded?).to be true
    end

    it 'is false when inclusive values are also present' do
      params[:f] = { '-rarity' => ['Common'] }
      allow(filter).to receive(:values).and_return(['Rare'])
      expect(component.excluded?).to be false
    end

    it 'is false when the facet is not excludable' do
      allow(facet_field_config).to receive(:excludable).and_return(false)
      params[:f] = { '-rarity' => ['Common'] }
      expect(component.excluded?).to be false
    end
  end

  describe '#filter_field_name' do
    it 'uses the inclusive param name by default' do
      expect(component.filter_field_name).to eq('f_inclusive[rarity][]')
    end

    it 'uses the negated f param name when excluded' do
      params[:f] = { '-rarity' => ['Common'] }
      expect(component.filter_field_name).to eq('f[-rarity][]')
    end
  end

  describe '#facet_field_label' do
    it 'uses the translation with the field key, falling back to the field label' do
      allow(component).to receive(:t).and_return('Rarity')
      expect(component.facet_field_label).to eq('Rarity')
    end
  end
end
