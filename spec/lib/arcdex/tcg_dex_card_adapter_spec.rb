# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::TcgDexCardAdapter do
  describe '#game' do
    it 'identifies the card as Pokémon TCG Pocket' do
      expect(described_class.new({}).game).to eq('Pokémon TCG Pocket')
    end
  end

  describe '#has_online_content?' do
    it 'is true for the tcgp serie' do
      adapter = described_class.new({ 'serie' => { 'id' => 'tcgp' } })
      expect(adapter.has_online_content?).to be(true)
    end

    it 'is false for any other serie' do
      adapter = described_class.new({ 'serie' => { 'id' => 'base' } })
      expect(adapter.has_online_content?).to be(false)
    end
  end
end
