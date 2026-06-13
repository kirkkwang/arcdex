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

  describe 'image urls' do
    subject(:adapter) { described_class.new({ 'id' => 'A1-001' }) }

    it 'points the full-res image at the downcased webp object on R2' do
      expect(adapter.large_image).to eq('https://images.arcdex.dev/a1-001.webp')
    end

    it 'serves the same webp object for the thumbnail' do
      expect(adapter.small_image).to eq(adapter.large_image)
    end
  end
end
