# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::TcgPlayerPricesComponent do
  subject { component }

  let(:component) { described_class.new(field:) }
  let(:prices) { { 'Holofoil' => { 'market' => 12.34, 'low' => nil }, 'Normal' => { 'market' => 5.0, 'low' => 4.5 } } }
  let(:document) do
    double('document', # rubocop:disable RSpec/VerifiedDoubles
           tcg_player_prices_object: prices,
           tcg_player_price_updated_at: '2024-03-01',
           tcg_player_url: 'https://tcgplayer.com/1')
  end
  let(:field_config) { double('field_config', compact: false) } # rubocop:disable RSpec/VerifiedDoubles
  let(:field) { double('field', document:, field_config:, key: 'tcg_player_prices') } # rubocop:disable RSpec/VerifiedDoubles

  describe '#format_price' do
    it 'formats a non-nil price as dollars with 2 decimal places' do
      expect(component.send(:format_price, 12.34)).to eq('$12.34')
    end

    it 'returns a dash for a nil price' do
      expect(component.send(:format_price, nil)).to eq('-')
    end
  end

  describe '#all_price_types' do
    it 'returns the keys from the first card type prices' do
      expect(component.send(:all_price_types)).to eq(%w[market low])
    end
  end

  describe '#last_updated_at (private)' do
    it 'returns a formatted last updated string' do
      allow(component).to receive(:t).with('.last_updated').and_return('Last updated')
      expect(component.send(:last_updated_at)).to eq('Last updated: 2024-03-01')
    end
  end
end
