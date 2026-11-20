# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::PokemonTcgIoCardAdapter do
  subject(:adapter) { described_class.new({}) }

  describe '#game' do
    it 'identifies the card as Pokémon TCG' do
      expect(adapter.game).to eq('Pokémon TCG')
    end
  end

  describe 'set logo and symbol' do
    def adapter_with(images)
      described_class.new([{ 'set' => { 'images' => images } }])
    end

    it 'rewrites dead images.pokemontcg.io set images to Scrydex' do
      adapter = adapter_with('logo' => 'https://images.pokemontcg.io/me6/logo.png',
                             'symbol' => 'https://images.pokemontcg.io/me6/symbol.png')
      expect([adapter.logo_url, adapter.symbol_url]).to eq(
        %w[https://images.scrydex.com/pokemon/me6-logo/logo https://images.scrydex.com/pokemon/me6-symbol/symbol]
      )
    end

    it 'leaves Scrydex and missing URLs alone' do
      adapter = adapter_with('logo' => 'https://images.scrydex.com/pokemon/me4-logo/logo')
      expect([adapter.logo_url, adapter.symbol_url]).to eq(['https://images.scrydex.com/pokemon/me4-logo/logo', nil])
    end
  end

  describe '#has_online_content?' do
    it 'is false (pokemontcg.io has no Pocket cards)' do
      expect(adapter.has_online_content?).to be(false)
    end
  end
end
