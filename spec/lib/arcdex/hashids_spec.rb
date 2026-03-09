# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Hashids do
  describe '.encode' do
    it 'returns a hashid of at least MIN_LENGTH characters' do
      result = described_class.encode(42)
      expect(result.length).to be >= Arcdex::Hashids::MIN_LENGTH
    end

    it 'returns a consistent encoding for the same input' do
      first = described_class.encode(1)
      second = described_class.encode(1)
      expect(first).to eq(second)
    end
  end

  describe '.decode' do
    it 'returns the original integer for a valid hashid' do
      hashid = described_class.encode(99)
      expect(described_class.decode(hashid)).to eq(99)
    end

    it 'returns nil when the hashid contains a hyphen (SolrDocument id)' do
      expect(described_class.decode('base-set-1')).to be_nil
    end
  end
end
