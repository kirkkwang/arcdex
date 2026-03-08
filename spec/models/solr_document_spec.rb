# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument do
  def build_doc(fields = {})
    described_class.new(fields)
  end

  describe '#series' do
    it 'returns the first series_ssm value' do
      doc = build_doc('series_ssm' => ['Base Set'])
      expect(doc.series).to eq('Base Set')
    end

    it 'returns an empty string when series_ssm is absent' do
      expect(build_doc.series).to eq('')
    end
  end

  describe '#master_set?' do
    it 'returns true when printed_total_isi < total_items_isi' do
      doc = build_doc('printed_total_isi' => 102, 'total_items_isi' => 110)
      expect(doc.master_set?).to be true
    end

    it 'returns false when printed_total_isi == total_items_isi' do
      doc = build_doc('printed_total_isi' => 102, 'total_items_isi' => 102)
      expect(doc.master_set?).to be false
    end
  end

  describe '#master_set_count' do
    it 'returns total_items_isi' do
      expect(build_doc('total_items_isi' => 110).master_set_count).to eq(110)
    end

    it 'returns empty string when absent' do
      expect(build_doc.master_set_count).to eq('')
    end
  end

  describe '#complete_set_count' do
    it 'returns printed_total_isi' do
      expect(build_doc('printed_total_isi' => 102).complete_set_count).to eq(102)
    end

    it 'returns empty string when absent' do
      expect(build_doc.complete_set_count).to eq('')
    end
  end

  describe '#logo_url' do
    it 'returns the first logo_url_ssm value' do
      expect(build_doc('logo_url_ssm' => ['https://example.com/logo.png']).logo_url).to eq('https://example.com/logo.png')
    end
  end

  describe '#release_date' do
    it 'returns the first release_date_ssm value' do
      expect(build_doc('release_date_ssm' => ['1999-01-09']).release_date).to eq('1999-01-09')
    end
  end

  describe '#icon_url' do
    context 'when the document is a collection' do
      it 'returns symbol_url_ssm' do
        doc = build_doc('level_ssm' => ['collection'], 'symbol_url_ssm' => ['https://example.com/symbol.png'])
        expect(doc.icon_url).to eq('https://example.com/symbol.png')
      end
    end

    context 'when the document is a card' do
      it 'returns small_url_ssm' do
        doc = build_doc('small_url_ssm' => ['https://example.com/small.png'])
        expect(doc.icon_url).to eq('https://example.com/small.png')
      end
    end
  end

  describe '#supertype' do
    it 'returns the first supertype_ssm value' do
      expect(build_doc('supertype_ssm' => ['Pokémon']).supertype).to eq('Pokémon')
    end
  end

  describe '#flavor_text_html' do
    it 'returns the first flavor_text_html_ssm value' do
      expect(build_doc('flavor_text_html_ssm' => ['<em>Flavorful</em>']).flavor_text_html).to eq('<em>Flavorful</em>')
    end

    it 'returns empty string when absent' do
      expect(build_doc.flavor_text_html).to eq('')
    end
  end

  describe '#image_html' do
    context 'when the document is a collection' do
      it 'returns logo_url_html_ssm' do
        doc = build_doc('level_ssm' => ['collection'], 'logo_url_html_ssm' => ['<img src="logo.png">'])
        expect(doc.image_html).to eq('<img src="logo.png">')
      end
    end

    context 'when the document is a card' do
      it 'returns large_url_html_ssm' do
        doc = build_doc('large_url_html_ssm' => ['<img src="large.png">'])
        expect(doc.image_html).to eq('<img src="large.png">')
      end
    end

    it 'returns empty string when absent' do
      expect(build_doc.image_html).to eq('')
    end
  end

  describe '#image_url' do
    context 'when the document is a collection' do
      it 'returns logo_url_ssm' do
        doc = build_doc('level_ssm' => ['collection'], 'logo_url_ssm' => ['https://example.com/logo.png'])
        expect(doc.image_url).to eq('https://example.com/logo.png')
      end
    end

    context 'when the document is a card' do
      it 'returns large_url_ssm' do
        doc = build_doc('large_url_ssm' => ['https://example.com/large.png'])
        expect(doc.image_url).to eq('https://example.com/large.png')
      end
    end
  end

  describe '#thumbnail_url' do
    context 'when the document is a collection' do
      it 'returns logo_url_ssm' do
        doc = build_doc('level_ssm' => ['collection'], 'logo_url_ssm' => ['https://example.com/logo.png'])
        expect(doc.thumbnail_url).to eq('https://example.com/logo.png')
      end
    end

    context 'when the document is a card' do
      it 'returns thumbnail_path_ssi' do
        doc = build_doc('thumbnail_path_ssi' => 'https://example.com/thumb.png')
        expect(doc.thumbnail_url).to eq('https://example.com/thumb.png')
      end
    end

    it 'returns empty string when absent' do
      expect(build_doc.thumbnail_url).to eq('')
    end
  end

  describe '#title' do
    it 'returns the first title_ssm value' do
      expect(build_doc('title_ssm' => ['Charizard']).title).to eq('Charizard')
    end
  end

  describe '#tcg_player_price_updated_at' do
    it 'returns the tcg_player_price_updated_at_ssi value' do
      expect(build_doc('tcg_player_price_updated_at_ssi' => '2024-01-01').tcg_player_price_updated_at).to eq('2024-01-01')
    end

    it 'returns empty string when absent' do
      expect(build_doc.tcg_player_price_updated_at).to eq('')
    end
  end

  describe '#tcg_player_prices_object' do
    it 'parses valid JSON' do
      json = '{"Holofoil":{"market":12.34}}'
      expect(build_doc('tcg_player_prices_json_ssi' => json).tcg_player_prices_object).to eq({ 'Holofoil' => { 'market' => 12.34 } })
    end

    it 'returns empty hash for invalid JSON' do
      expect(build_doc('tcg_player_prices_json_ssi' => 'not-json').tcg_player_prices_object).to eq({})
    end

    it 'returns empty hash when field is nil' do
      expect(build_doc.tcg_player_prices_object).to eq({})
    end
  end

  describe '#tcg_player_url' do
    it 'returns the tcg_player_url_ssi value' do
      expect(build_doc('tcg_player_url_ssi' => 'https://tcgplayer.com/1').tcg_player_url).to eq('https://tcgplayer.com/1')
    end

    it 'returns empty string when absent' do
      expect(build_doc.tcg_player_url).to eq('')
    end
  end

  describe '#cardmarket_price_updated_at' do
    it 'returns the cardmarket_price_updated_at_ssi value' do
      expect(build_doc('cardmarket_price_updated_at_ssi' => '2024-02-01').cardmarket_price_updated_at).to eq('2024-02-01')
    end

    it 'returns empty string when absent' do
      expect(build_doc.cardmarket_price_updated_at).to eq('')
    end
  end

  describe '#cardmarket_prices_object' do
    it 'parses valid JSON' do
      json = '{"avg1":2.5}'
      expect(build_doc('cardmarket_prices_json_ssi' => json).cardmarket_prices_object).to eq({ 'avg1' => 2.5 })
    end

    it 'returns empty hash for invalid JSON' do
      expect(build_doc('cardmarket_prices_json_ssi' => '!!!').cardmarket_prices_object).to eq({})
    end

    it 'returns empty hash when field is nil' do
      expect(build_doc.cardmarket_prices_object).to eq({})
    end
  end

  describe '#cardmarket_url' do
    it 'returns the cardmarket_url_ssi value' do
      expect(build_doc('cardmarket_url_ssi' => 'https://cardmarket.com/1').cardmarket_url).to eq('https://cardmarket.com/1')
    end

    it 'returns empty string when absent' do
      expect(build_doc.cardmarket_url).to eq('')
    end
  end

  describe '#repository' do
    context 'when series_ssm is absent but collection has series_ssm' do
      let(:doc) { build_doc }
      let(:collection_doc) { build_doc('series_ssm' => ['Base Set']) }

      before { allow(doc).to receive(:collection).and_return(collection_doc) }

      it 'falls back to the collection series_ssm' do
        expect(doc.repository).to eq('Base Set')
      end
    end
  end

  describe '#repository_config' do
    context 'when repository is nil' do
      let(:doc) { build_doc }

      before { allow(doc).to receive(:collection).and_return(nil) }

      it 'returns nil' do
        expect(doc.repository_config).to be_nil
      end
    end

    context 'when repository is present' do
      let(:doc) { build_doc('series_ssm' => ['Jungle']) }
      let(:repo) do
        instance_double(Arclight::Repository,
                        name: 'Jungle',
                        final_set_release_date: Date.new(2020, 1, 1),
                        documents: [])
      end

      before { allow(Arclight::Repository).to receive(:all).and_return([repo]) }

      it 'returns the matching Arclight::Repository' do
        expect(doc.repository_config).to eq(repo)
      end
    end
  end

  describe '#collection_unitid' do
    context 'when collection is present' do
      let(:doc) { build_doc }
      let(:collection_doc) { build_doc('id' => 'jungle-1') }

      before { allow(doc).to receive(:collection).and_return(collection_doc) }

      it 'returns the collection id' do
        expect(doc.collection_unitid).to eq('jungle-1')
      end
    end
  end

  describe '#cards' do
    it 'returns an empty array when cards field is absent' do
      expect(build_doc.cards).to eq([])
    end

    it 'returns SolrDocument instances for each card hash' do
      doc = build_doc('cards' => { 'docs' => [{ 'id' => 'card-1', 'title_ssm' => ['Pikachu'] }] })
      expect(doc.cards).to all(be_a(described_class))
      expect(doc.cards.first.title).to eq('Pikachu')
    end
  end
end
