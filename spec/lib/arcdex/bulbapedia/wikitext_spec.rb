# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Bulbapedia::Wikitext do
  describe '.templates' do
    it 'extracts params from each matching template, handling nesting' do
      text = "{{Cardtext/Attack/Pocket|name=Ram|cost={{e|Colorless}}|damage=10}}" \
             "{{Cardtext/Attack/Pocket|name=Tackle|cost={{e|Water}}{{e|Water}}|damage=30}}"
      result = described_class.templates(text, 'Cardtext/Attack/Pocket')
      expect(result.pluck('name')).to eq(%w[Ram Tackle])
      expect(result.first['cost']).to eq('{{e|Colorless}}')
    end

    it 'respects name boundaries so a prefix does not match a longer name' do
      text = '{{Infobox/Pokémon/Pocket|a=1}}{{Infobox/Pokémon|b=2}}'
      expect(described_class.templates(text, 'Infobox/Pokémon').size).to eq(1)
    end

    it 'captures bare positional params' do
      header = described_class.template(text_with_header, 'TCG Card Infobox/Expansion Header/Pocket')
      expect(header['_positional']).to eq(['Paradox Drive'])
    end
  end

  describe '.energy' do
    it 'lists each energy symbol' do
      expect(described_class.energy('{{e|Lightning}}{{e|Lightning}}')).to eq(%w[Lightning Lightning])
    end

    it 'returns an empty array for no energy' do
      expect(described_class.energy('')).to eq([])
      expect(described_class.energy(nil)).to eq([])
    end
  end

  describe '.clean' do
    it 'reduces links and templates to plain text' do
      expect(described_class.clean("attach to your {{TCGP|Ancient}} [[Pokémon]]"))
        .to eq('attach to your Ancient Pokémon')
      expect(described_class.clean("[[hncl|Illus. hncl]]")).to eq('Illus. hncl')
    end

    it 'strips the TCGP Icon template used in ex card names' do
      expect(described_class.clean('Iron Bundle {{TCGP Icon|ex}}')).to eq('Iron Bundle ex')
    end

    it 'returns nil for blank values' do
      expect(described_class.clean('')).to be_nil
      expect(described_class.clean(nil)).to be_nil
    end
  end

  def text_with_header
    '{{TCG Card Infobox/Expansion Header/Pocket|Paradox Drive}}'
  end
end
