# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::BulbapediaCardAdapter do
  describe 'a card record' do
    subject(:adapter) { described_class.new(card) }

    let(:card) do
      {
        '_source' => 'bulbapedia', 'id' => 'B3a-001', 'number' => '001', 'name' => 'Surskit',
        'supertype' => 'Pokémon', 'subtypes' => ['Basic'], 'hp' => 60, 'types' => ['Grass'],
        'weaknesses' => [{ 'type' => 'Fire', 'value' => '+20' }], 'retreat' => 1, 'rarity' => 'Diamond',
        'illustrator' => 'Yoriyuki Ikegami',
        'attacks' => [{ 'name' => 'Ram', 'cost' => ['Colorless'], 'damage' => '10', 'effect' => nil }],
        'abilities' => nil, 'flavor_text' => 'It secretes…', 'national_pokedex_numbers' => [283], 'boosters' => []
      }
    end

    it 'downcases the id and reports the game' do
      expect(adapter.id).to eq('b3a-001')
      expect(adapter.game).to eq('Pokémon TCG Pocket')
      expect(adapter.has_online_content?).to be(true)
    end

    it 'derives the series from the set code letter' do
      expect(adapter.series).to eq('B Series')
    end

    it 'points images at the R2 webp keyed by id' do
      expect(adapter.large_image).to eq('https://images.arcdex.dev/b3a-001.webp')
      expect(adapter.small_image).to eq(adapter.large_image)
    end

    it 'maps card stats and attack accessors' do
      expect(adapter.hp).to eq(60)
      expect(adapter.types).to eq(['Grass'])
      expect(adapter.number).to eq(1)
      expect(adapter.retreat_cost).to eq('Colorless')
      expect(adapter.converted_retreat_cost).to eq(1)
      expect(adapter.attack_name(0)).to eq('Ram')
      expect(adapter.attack_cost(0)).to eq(['Colorless'])
      expect(adapter.attack_converted_energy_cost(0)).to eq(1)
      expect(adapter.weakness_type(0)).to eq('Fire')
      expect(adapter.weakness_value(0)).to eq('+20')
    end

    it 'returns nil for pricing (Pocket has none)' do
      expect(adapter.tcgplayer_prices).to be_nil
      expect(adapter.cardmarket).to be_nil
    end
  end

  describe 'a promo card record' do
    subject(:adapter) do
      described_class.new('_source' => 'bulbapedia', 'id' => 'Promo-A-074', 'number' => '074',
                          'supertype' => 'Pokémon', 'retreat' => 0)
    end

    it 'downcases the promo id to match the Drive filename convention' do
      expect(adapter.id).to eq('promo-a-074')
      expect(adapter.large_image).to eq('https://images.arcdex.dev/promo-a-074.webp')
    end

    it 'groups promos with their letter series (Promo-A -> A Series), matching TCGdex' do
      expect(adapter.series).to eq('A Series')
    end
  end

  describe 'a promo set record' do
    subject(:adapter) { described_class.new('_source' => 'bulbapedia', 'id' => 'Promo-A', 'name' => 'Promo-A', 'cards' => []) }

    it 'downcases set_id and keys logo/symbol to promo-a' do
      expect(adapter.set_id).to eq('promo-a')
      expect(adapter.logo_url).to eq('https://images.arcdex.dev/promo-a-logo.webp')
      expect(adapter.symbol_url).to eq('https://images.arcdex.dev/promo-a-symbol.webp')
    end
  end

  describe 'a set record' do
    subject(:adapter) { described_class.new(set) }

    let(:set) do
      { '_source' => 'bulbapedia', 'id' => 'B3a', 'name' => 'Paradox Drive', 'release_date' => '2026-05-28',
        'printed_total' => 74, 'total' => 109, 'cards' => [{ 'id' => 'B3a-001' }] }
    end

    it 'maps set-level fields' do
      expect(adapter.set_id).to eq('b3a')
      expect(adapter.set_name).to eq('Paradox Drive')
      expect(adapter.printed_total).to eq(74)
      expect(adapter.total).to eq(109)
      expect(adapter.child_component_count).to eq(1)
    end

    it 'points logo and symbol at R2 webp keyed by set code' do
      expect(adapter.logo_url).to eq('https://images.arcdex.dev/b3a-logo.webp')
      expect(adapter.symbol_url).to eq('https://images.arcdex.dev/b3a-symbol.webp')
    end
  end
end
