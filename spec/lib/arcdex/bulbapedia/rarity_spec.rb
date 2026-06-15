# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Bulbapedia::Rarity do
  describe '.name' do
    {
      %w[Diamond 1] => 'Common',
      %w[Diamond 2] => 'Uncommon',
      %w[Diamond 3] => 'Rare',
      %w[Diamond 4] => 'Double Rare',
      %w[Star 1] => 'Illustration Rare',
      %w[Star 2] => 'Super Rare',
      %w[Star 3] => 'Immersive Rare',
      %w[Shiny 1] => 'Shiny Rare',
      %w[Shiny 2] => 'Shiny Super Rare',
      %w[Crown 1] => 'Ultra Rare'
    }.each do |(symbol, count), expected|
      it "maps #{symbol}|#{count} to #{expected}" do
        expect(described_class.name(symbol, count)).to eq(expected)
      end
    end

    it 'treats a missing count as 1 (e.g. {{rar/TCGP|Crown}})' do
      expect(described_class.name('Crown')).to eq('Ultra Rare')
    end

    it 'falls back to the symbol for an unknown combo' do
      expect(described_class.name('Diamond', '9')).to eq('Diamond')
    end

    it 'returns nil when there is no symbol (e.g. promo cards)' do
      expect(described_class.name(nil, nil)).to be_nil
    end
  end
end
