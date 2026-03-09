# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::IiifPresentable do
  subject(:obj) { test_class.new }

  let(:test_class) do
    Class.new do
      include Arcdex::IiifPresentable
    end
  end

  describe '#presentation_api_url' do
    it 'returns the IIIF v3 context URL' do
      expect(obj.presentation_api_url).to eq('http://iiif.io/api/presentation/3/context.json')
    end
  end

  describe '#rights_statement' do
    it 'returns the InC rights URL' do
      expect(obj.rights_statement).to eq('http://rightsstatements.org/vocab/InC/1.0/')
    end
  end

  describe '#required_statement' do
    it 'returns a hash with attribution label and Pokémon TCG Developers value' do
      result = obj.required_statement
      expect(result[:label]).to eq({ en: ['Attribution'] })
      expect(result[:value][:en].first).to include('Pokémon TCG Developers')
    end
  end

  describe '#thumbnail_height' do
    it { expect(obj.thumbnail_height).to eq(342) }
  end

  describe '#thumbnail_width' do
    it { expect(obj.thumbnail_width).to eq(245) }
  end

  describe '#thumbnail_body' do
    let(:url) { 'https://example.com/image.png' }

    it 'returns an Image object hash with the given URL' do
      result = obj.thumbnail_body(url)
      expect(result[:id]).to eq(url)
      expect(result[:type]).to eq('Image')
      expect(result[:height]).to eq(342)
      expect(result[:width]).to eq(245)
      expect(result[:format]).to eq('image/png')
    end
  end
end
