# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::IiifCanvasesPresenter do
  subject(:presenter) { described_class.new(documents: [document], base_url:, fields:) }

  let(:document) do
    SolrDocument.new(
      'id' => 'base-1-001',
      'title_ssm' => ['Charizard'],
      'large_url_ssm' => ['https://example.com/image.png'],
      'thumbnail_path_ssi' => 'https://example.com/thumb.png',
      'series_ssm' => ['Base']
    )
  end
  let(:base_url) { 'https://arcdex.example.com/catalog' }
  let(:fields) { {} }

  describe '#initialize' do
    it 'exposes documents, base_url, and fields' do
      expect(presenter.documents).to eq([document])
      expect(presenter.base_url).to eq(base_url)
      expect(presenter.fields).to eq(fields)
    end
  end

  describe '#as_json' do
    subject(:json) { presenter.as_json }

    it 'returns one canvas per document' do
      expect(json.length).to eq(1)
    end

    it 'sets type to Canvas' do
      expect(json.first[:type]).to eq('Canvas')
    end

    it 'sets the canvas id using the document id' do
      expect(json.first[:id]).to include('base-1-001')
      expect(json.first[:id]).to include('canvas')
    end

    it 'sets label from document title' do
      expect(json.first[:label]).to eq({ en: ['Charizard'] })
    end

    it 'sets height and width' do
      expect(json.first[:height]).to eq(1024)
      expect(json.first[:width]).to eq(733)
    end

    it 'includes items (annotation page)' do
      items = json.first[:items]
      expect(items.length).to eq(1)
      expect(items.first[:type]).to eq('AnnotationPage')
    end

    it 'includes thumbnail' do
      expect(json.first[:thumbnail].first[:id]).to eq('https://example.com/thumb.png')
      expect(json.first[:thumbnail].first[:type]).to eq('Image')
    end

    it 'includes homepage' do
      expect(json.first[:homepage].first[:type]).to eq('Text')
    end

    it 'includes partOf when series is present' do
      expect(json.first[:partOf]).to be_an(Array)
      expect(json.first[:partOf].first[:type]).to eq('Collection')
    end

    context 'when document has no series' do
      let(:document) do
        SolrDocument.new(
          'id' => 'base-1-001',
          'title_ssm' => ['Charizard'],
          'large_url_ssm' => ['https://example.com/image.png'],
          'thumbnail_path_ssi' => 'https://example.com/thumb.png'
        )
      end

      it 'omits partOf' do
        expect(json.first).not_to have_key(:partOf)
      end
    end

    context 'with metadata fields' do
      let(:field_config) { double('field_config', field: 'rarity_ssm') } # rubocop:disable RSpec/VerifiedDoubles
      let(:fields) { { 'Rarity' => field_config } }
      let(:document) do
        SolrDocument.new(
          'id' => 'base-1-001',
          'title_ssm' => ['Charizard'],
          'large_url_ssm' => ['https://example.com/image.png'],
          'thumbnail_path_ssi' => 'https://example.com/thumb.png',
          'rarity_ssm' => ['Rare Holo']
        )
      end

      it 'includes canvas metadata' do
        expect(json.first[:metadata]).not_to be_empty
        expect(json.first[:metadata].first[:label]).to eq({ en: ['Rarity'] })
        expect(json.first[:metadata].first[:value][:en].first).to include('Rare Holo')
      end
    end
  end
end
