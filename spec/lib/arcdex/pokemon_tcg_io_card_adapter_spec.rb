# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::PokemonTcgIoCardAdapter do
  subject(:adapter) { described_class.new({}) }

  describe '#game' do
    it 'identifies the card as Pokémon TCG' do
      expect(adapter.game).to eq('Pokémon TCG')
    end
  end

  describe '#has_online_content?' do
    it 'is false (pokemontcg.io has no Pocket cards)' do
      expect(adapter.has_online_content?).to be(false)
    end
  end
end
