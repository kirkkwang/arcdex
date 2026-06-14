# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Bulbapedia::ExpansionParser do
  subject(:parsed) { described_class.parse(wikitext) }

  let(:wikitext) { Rails.root.join('spec/fixtures/bulbapedia/paradox_drive_expansion.wikitext').read }

  it 'extracts set-level fields' do
    expect(parsed).to include(
      'id' => 'B3a',
      'name' => 'Paradox Drive',
      'release_date' => '2026-05-28',
      'printed_total' => 74,
      'total' => 109
    )
  end

  it 'extracts card-list rows with number, name and local number' do
    surskit = parsed['rows'].find { |r| r['name'] == 'Surskit' }
    expect(surskit).to include('number' => '001', 'local_number' => '1', 'type' => 'Grass', 'rarity' => 'Diamond')
  end

  it 'derives release_date in YYYY-MM-DD form' do
    expect(parsed['release_date']).to match(/\A\d{4}-\d{2}-\d{2}\z/)
  end

  it 'enumerates every card including secret rares (109, not just the 90 base/3-param rows)' do
    expect(parsed['rows'].size).to eq(109)
  end

  it 'captures 4-param ex cards using the display name and number' do
    iron_bundle_ex = parsed['rows'].find { |r| r['name'] == 'Iron Bundle ex' && r['number'] == '013' }
    expect(iron_bundle_ex).to include('local_number' => '13')
  end

  describe 'infobox edge cases' do
    it 'handles a plain card count with no secret split' do
      wikitext = "{{TCGPocketExpansionInfobox\n|setname=X\n|setlogo=Z9 Set Logo EN.png\n|release=May 1, 2025\n|cards=30\n}}"
      expect(described_class.parse(wikitext)).to include('printed_total' => 30, 'total' => 30, 'id' => 'Z9')
    end

    it 'returns nil release_date when the date is unparseable' do
      wikitext = "{{TCGPocketExpansionInfobox\n|setname=X\n|release=TBA\n|cards=10\n}}"
      expect(described_class.parse(wikitext)['release_date']).to be_nil
    end

    it 'returns nil set code when setlogo is absent' do
      wikitext = "{{TCGPocketExpansionInfobox\n|setname=X\n|cards=10\n}}"
      expect(described_class.parse(wikitext)['id']).to be_nil
    end

    it 'canonicalizes the promo set code to match the Drive (PA logo -> Promo-A)' do
      wikitext = "{{TCGPocketExpansionInfobox\n|setname=Promo-A\n|setlogo=PA Set Logo EN.png\n|cards=117\n}}"
      expect(described_class.parse(wikitext)['id']).to eq('Promo-A')
    end

    it 'ignores a {{TCG ID}} that is not a real table row (e.g. a footnote)' do
      wikitext = <<~WIKI
        == Card list ==
        {{TCG Set List/header}}
        |-
        | 001/010 || {{TCG ID|X|Surskit|1}} || {{TCG Icon|Grass}} || {{Rar/TCGP|Diamond|1}}
        |}
        * {{TCG ID|X|Surskit|1}} = reprint note, not a card row
      WIKI
      rows = described_class.parse(wikitext)['rows']
      expect(rows.size).to eq(1)
      expect(rows.first['number']).to eq('001')
    end
  end
end
