# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::PokemonSearchComponent do
  let(:document) { SolrDocument.new('supertype_ssm' => ['Pokémon']) }
  let(:field_config) { double('field_config', compact: false, truncate: false, label: 'Evolves From') } # rubocop:disable RSpec/VerifiedDoubles
  let(:field) { double('field', document:, field_config:, key: 'pokemon_search') } # rubocop:disable RSpec/VerifiedDoubles

  let(:helpers_double) { double('helpers', search_action_url: '/catalog?q=test') } # rubocop:disable RSpec/VerifiedDoubles
  let(:component) do
    described_class.new(field:).tap do |c|
      allow(c).to receive(:link_to) { |val, _url| "<a>#{val}</a>" }
      allow(c).to receive(:helpers).and_return(helpers_double)
    end
  end

  describe '#label' do
    it 'appends a colon to the field config label' do
      expect(component.label).to eq('Evolves From:')
    end
  end

  describe '#pokemon_search' do
    it 'wraps each value in a link' do
      result = component.pokemon_search('evolves_from_ssm', ['Charmander'])
      expect(result).to include('<a>')
      expect(result).to include('Charmander')
    end

    it 'handles evolves_to fields' do
      result = component.pokemon_search('evolves_to_ssm', ['Charizard'])
      expect(result).to include('Charizard')
    end

    it 'handles fields that are neither evolves_from nor evolves_to' do
      result = component.pokemon_search('other_field', ['Raichu'])
      expect(result).to include('Raichu')
    end

    it 'joins multiple values with "or"' do
      result = component.pokemon_search('evolves_from_ssm', ['Charmander', 'Charmeleon'])
      expect(result).to include(' or ')
    end
  end
end
