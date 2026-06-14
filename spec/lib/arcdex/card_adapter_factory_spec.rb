# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::CardAdapterFactory do
  describe '.call' do
    it 'routes records with the bulbapedia marker to the Bulbapedia adapter' do
      record = { '_source' => 'bulbapedia', 'id' => 'B3a-001' }
      expect(described_class.call(record)).to be_a(Arcdex::BulbapediaCardAdapter)
    end

    it 'routes legacy TCGdex pocket records (non-pokemontcg images) to the TcgDex adapter' do
      record = { 'images' => { 'small' => 'https://assets.tcgdex.net/en/tcgp/A1/1/low.png' } }
      expect(described_class.call(record)).to be_a(Arcdex::TcgDexCardAdapter)
    end

    it 'routes pokemontcg.io records to the pokemontcg.io adapter' do
      record = { 'images' => { 'small' => 'https://images.pokemontcg.io/base1/1.png' } }
      expect(described_class.call(record)).to be_a(Arcdex::PokemonTcgIoCardAdapter)
    end
  end
end
