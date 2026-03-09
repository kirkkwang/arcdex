# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::IiifManifestPresenter do
  let(:set_id) { 'base-1' }
  let(:start_id) { 'base-1-001' }
  let(:base_url) { 'https://arcdex.example.com/catalog' }
  let(:document) do
    SolrDocument.new(
      'id' => 'base-1-001',
      'series_ssm' => ['Base'],
      'parent_unittitles_ssm' => ['Base Set']
    )
  end
  let(:documents) { [document] }
  let(:fields) { [] }
  let(:set_document) do
    double('set_document', series: 'Base', thumbnail_url: 'https://example.com/thumb.png') # rubocop:disable RSpec/VerifiedDoubles
  end
  let(:canvases_presenter) { double('canvases_presenter', as_json: []) } # rubocop:disable RSpec/VerifiedDoubles

  before do
    allow(SolrDocument).to receive(:find).with(set_id).and_return(set_document)
    allow(Arcdex::IiifCanvasesPresenter).to receive(:new).and_return(canvases_presenter)
  end

  describe '#initialize' do
    context 'when from_bookmarks is false' do
      subject(:presenter) { described_class.new(base_url:, start_id:, fields:, documents:, set_id:) }

      it 'fetches and stores the series from SolrDocument' do
        expect(presenter.series).to eq('Base')
      end
    end

    context 'when from_bookmarks is true' do
      subject(:presenter) { described_class.new(base_url:, start_id:, fields:, documents:, set_id:, from_bookmarks: true) }

      it 'does not call SolrDocument.find' do
        expect(SolrDocument).not_to have_received(:find)
      end

      it 'sets from_bookmarks to true' do
        expect(presenter.from_bookmarks).to be(true)
      end
    end
  end

  describe '#as_json' do
    context 'when from_bookmarks is false and start_id differs from set_id' do
      subject(:json) do
        described_class.new(base_url:, start_id:, fields:, documents:, set_id:).as_json
      end

      it 'includes the IIIF presentation context' do
        expect(json['@context']).to eq('http://iiif.io/api/presentation/3/context.json')
      end

      it 'sets type to Manifest' do
        expect(json[:type]).to eq('Manifest')
      end

      it 'sets the manifest id using base_url and set_id' do
        expect(json[:id]).to eq("#{base_url}/#{set_id}/manifest")
      end

      it 'includes a start canvas pointing to the start_id' do
        expect(json[:start][:id]).to eq("#{base_url}/#{start_id}/canvas")
        expect(json[:start][:type]).to eq('Canvas')
      end

      it 'sets label from series and parent unit title' do
        expect(json[:label]).to eq({ en: ['Base - Base Set'] })
      end

      it 'includes items from IiifCanvasesPresenter' do
        expect(json[:items]).to eq([])
      end

      it 'includes rights statement' do
        expect(json[:rights]).to eq('http://rightsstatements.org/vocab/InC/1.0/')
      end

      it 'includes required statement' do
        expect(json[:requiredStatement][:label]).to eq({ en: ['Attribution'] })
      end

      it 'includes homepage' do
        expect(json[:homepage]).to be_an(Array)
        expect(json[:homepage].first[:type]).to eq('Text')
      end

      it 'includes thumbnail from SolrDocument' do
        expect(json[:thumbnail].first[:id]).to eq('https://example.com/thumb.png')
      end

      it 'includes partOf when series is present' do
        expect(json[:partOf]).to be_an(Array)
        expect(json[:partOf].first[:type]).to eq('Collection')
      end
    end

    context 'when start_id equals set_id' do
      subject(:json) do
        described_class.new(base_url:, start_id: set_id, fields:, documents:, set_id:).as_json
      end

      it 'omits the start key' do
        expect(json).not_to have_key(:start)
      end
    end

    context 'when from_bookmarks is true' do
      subject(:json) do
        described_class.new(base_url:, start_id:, fields:, documents:, set_id:, from_bookmarks: true).as_json
      end

      it 'sets label to Custom Set' do
        expect(json[:label]).to eq({ en: ['Custom Set'] })
      end

      it 'omits homepage' do
        expect(json).not_to have_key(:homepage)
      end

      it 'omits thumbnail' do
        expect(json).not_to have_key(:thumbnail)
      end

      it 'omits partOf' do
        expect(json).not_to have_key(:partOf)
      end
    end

    context 'when series is blank' do
      subject(:json) do
        described_class.new(base_url:, start_id:, fields:, documents:, set_id:).as_json
      end

      before do
        allow(set_document).to receive(:series).and_return(nil)
      end

      it 'omits partOf' do
        expect(json).not_to have_key(:partOf)
      end
    end
  end
end
