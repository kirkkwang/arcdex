# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::IiifCollectionPresenter do
  subject(:presenter) { described_class.new(series:, base_url:) }

  let(:set_doc) do
    double('set_doc', title: 'Base Set', id: 'base-1', thumbnail_url: 'https://example.com/base.png') # rubocop:disable RSpec/VerifiedDoubles
  end
  let(:series) do
    double('series', name: 'Base', documents: [set_doc]) # rubocop:disable RSpec/VerifiedDoubles
  end
  let(:base_url) { 'https://arcdex.example.com/series' }

  describe '#initialize' do
    it 'exposes series and base_url' do
      expect(presenter.series).to eq(series)
      expect(presenter.base_url).to eq(base_url)
    end
  end

  describe '#as_json' do
    subject(:json) { presenter.as_json }

    it 'includes the IIIF presentation context' do
      expect(json['@context']).to eq('http://iiif.io/api/presentation/3/context.json')
    end

    it 'sets the collection id using base_url and series name' do
      expect(json[:id]).to eq('https://arcdex.example.com/series/Base/manifest')
    end

    it 'sets type to Collection' do
      expect(json[:type]).to eq('Collection')
    end

    it 'sets label from series name' do
      expect(json[:label]).to eq({ en: ['Base'] })
    end

    it 'includes rights statement' do
      expect(json[:rights]).to eq('http://rightsstatements.org/vocab/InC/1.0/')
    end

    it 'includes required statement' do
      expect(json[:requiredStatement]).to be_a(Hash)
      expect(json[:requiredStatement][:label]).to eq({ en: ['Attribution'] })
    end

    it 'maps documents to manifest items' do
      items = json[:items]
      expect(items.length).to eq(1)
      expect(items.first[:type]).to eq('Manifest')
      expect(items.first[:label]).to eq({ en: ['Base Set'] })
    end

    it 'transforms /series path to /catalog in item ids' do
      item_id = json[:items].first[:id]
      expect(item_id).to include('/catalog/')
      expect(item_id).not_to include('/series/')
    end

    it 'includes thumbnail in each item' do
      thumbnail = json[:items].first[:thumbnail].first
      expect(thumbnail[:id]).to eq('https://example.com/base.png')
      expect(thumbnail[:type]).to eq('Image')
    end
  end
end
