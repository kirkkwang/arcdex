# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::CardmarketPricesComponent do
  subject(:component) { described_class.new(field:) }

  let(:document) do
    double('document', # rubocop:disable RSpec/VerifiedDoubles
           cardmarket_prices_object: { 'avg1' => 1.5, 'avg7' => nil },
           cardmarket_price_updated_at: '2024-01-15',
           cardmarket_url: 'https://cardmarket.com/1')
  end

  let(:field_config) { double('field_config', compact: false) } # rubocop:disable RSpec/VerifiedDoubles
  let(:field) { double('field', document:, field_config:, key: 'cardmarket_prices') } # rubocop:disable RSpec/VerifiedDoubles


  describe '#format_price' do
    it 'formats a non-nil price as euros with 2 decimal places' do
      expect(component.send(:format_price, 1.5)).to eq('1.50 €')
    end

    it 'returns a dash for a nil price' do
      expect(component.send(:format_price, nil)).to eq('-')
    end
  end

  describe '#all_price_types' do
    it 'returns the keys from the prices object' do
      expect(component.send(:all_price_types)).to eq(%w[avg1 avg7])
    end
  end
end
