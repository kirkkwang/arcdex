# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Arcdex::Bulbapedia::CardParser do
  def fixture(name)
    Rails.root.join('spec/fixtures/bulbapedia', name).read
  end

  describe 'a Pokémon card' do
    subject(:card) do
      described_class.parse(fixture('surskit_pokemon.wikitext'),
                            set_code: 'B3a', set_name: 'Paradox Drive',
                            row: { 'number' => '001', 'name' => 'Surskit', 'rarity' => 'Diamond' })
    end

    it 'maps identity and set membership' do
      expect(card).to include('_source' => 'bulbapedia', 'id' => 'B3a-001',
                              'number' => '001', 'rarity' => 'Diamond', 'supertype' => 'Pokémon')
    end

    it 'maps stats' do
      expect(card).to include('hp' => 60, 'types' => ['Grass'], 'subtypes' => ['Basic'], 'retreat' => 1)
      expect(card['weaknesses']).to eq([{ 'type' => 'Fire', 'value' => '+20' }])
    end

    it 'maps the attack with energy cost' do
      expect(card['attacks']).to eq([{ 'name' => 'Ram', 'cost' => ['Colorless'], 'damage' => '10', 'effect' => nil }])
    end

    it 'maps dex flavor text and national pokedex number' do
      expect(card['flavor_text']).to start_with('It secretes a thick')
      expect(card['national_pokedex_numbers']).to eq([283])
    end
  end

  describe 'a card with an ability and multiple printings' do
    subject(:card) do
      described_class.parse(fixture('zeraora_ability.wikitext'),
                            set_code: 'A3a', set_name: 'Extradimensional Crisis',
                            row: { 'number' => '021', 'name' => 'Zeraora', 'rarity' => 'Diamond' })
    end

    it 'parses the ability' do
      expect(card['abilities'].size).to eq(1)
      expect(card['abilities'].first).to include('name' => 'Thunderclap Flash', 'type' => 'Lightning')
      expect(card['abilities'].first['effect']).to start_with('At the end of your first turn')
    end

    it 'parses multi-energy attack cost' do
      expect(card['attacks'].first['cost']).to eq(%w[Lightning Lightning])
    end

    it 'falls back to the tabbed-image illustrator' do
      expect(card['illustrator']).to eq('kawayoo')
    end
  end

  describe 'a Trainer card' do
    subject(:card) do
      described_class.parse(fixture('professor_sada_trainer.wikitext'),
                            set_code: 'B3a', set_name: 'Paradox Drive',
                            row: { 'number' => '072', 'name' => 'Professor Sada', 'rarity' => 'Diamond' })
    end

    it 'identifies a Trainer and its subtype' do
      expect(card).to include('supertype' => 'Trainer', 'subtypes' => ['Supporter'], 'illustrator' => 'hncl')
    end

    it 'surfaces trainer rule text as flavor_text' do
      expect(card['flavor_text']).to start_with('Attach 3 different types of Energy')
    end

    it 'has no attacks or abilities' do
      expect(card['attacks']).to be_nil
      expect(card['abilities']).to be_nil
    end
  end

  describe 'field normalization edge cases' do
    def parse(wikitext)
      described_class.parse(wikitext, set_code: 'A1', set_name: 'Genetic Apex',
                                      row: { 'number' => '001', 'name' => 'X', 'rarity' => 'Common' })
    end

    it 'represents an attack with no damage as nil (not an empty string)' do
      wikitext = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=X\n|type=Grass\n|hp=60\n}}" \
                 "{{Cardtext/Attack/Pocket|type=Grass|cost={{e|Grass}}|name=Sleep|damage=|effect=Sleep.}}"
      expect(parse(wikitext)['attacks'].first['damage']).to be_nil
    end

    it 'returns nil weaknesses when the infobox weakness is none' do
      wikitext = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=X\n|type=Colorless\n|hp=60\n|weakness=none\n}}"
      expect(parse(wikitext)['weaknesses']).to be_nil
    end

    it 'ignores a non-numeric ndex instead of yielding [0]' do
      wikitext = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=X\n|type=Grass\n|hp=60\n}}" \
                 "{{Carddex/Pocket|name=X|ndex=—|dex=...}}"
      expect(parse(wikitext)['national_pokedex_numbers']).to eq([])
    end

    it 'adds the Future paradox subtype alongside the evo stage' do
      wikitext = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=Iron Moth\n|type=Fire\n|hp=90\n|evo stage=Basic\n}}" \
                 '{{Cardtext/Future/Pocket}}'
      expect(parse(wikitext)['subtypes']).to eq(%w[Basic Future])
    end

    it 'adds the Ancient paradox subtype' do
      wikitext = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=Raging Bolt\n|type=Dragon\n|hp=90\n|evo stage=Basic\n}}" \
                 '{{Cardtext/Ancient/Pocket}}'
      expect(parse(wikitext)['subtypes']).to eq(%w[Basic Ancient])
    end

    it 'omits a paradox subtype for non-paradox cards' do
      wikitext = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=X\n|type=Grass\n|hp=60\n|evo stage=Basic\n}}"
      expect(parse(wikitext)['subtypes']).to eq(['Basic'])
    end

    it 'adds the ex subtype from the {{TCGP Icon|ex}} name marker' do
      wikitext = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=Iron Bundle {{TCGP Icon|ex}}\n|type=Water\n|hp=130\n|evo stage=Basic\n}}" \
                 '{{Cardtext/Future/Pocket}}'
      expect(parse(wikitext)['subtypes']).to eq(%w[Basic Future ex])
    end

    it 'treats Mega ex cards as both MEGA and ex' do
      wikitext = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=Mega Pidgeot {{TCGP Icon|Mega ex}}\n|type=Colorless\n|hp=150\n|evo stage=Stage 2\n}}"
      expect(parse(wikitext)['subtypes']).to eq(['Stage 2', 'MEGA', 'ex'])
    end
  end

  describe 'Star|2 rarity disambiguation via tabbed-image caption' do
    let(:wikitext) do
      <<~WIKI
        {{TCG Card Infobox/Pokémon/Pocket
        |en name=Iron Bundle {{TCGP Icon|ex}}
        |type=Water
        |hp=130
        |image set=
        {{TCG Card Infobox/Tabbed Image/Pocket|image=IronBundleexParadoxDrive81.png|tab caption=Super Rare}}
        {{TCG Card Infobox/Tabbed Image/Pocket|image=IronBundleexParadoxDrive89.png|tab caption=Special Illustration Rare}}
        }}
      WIKI
    end

    # row rarity is the already-mapped set-list value ("Super Rare" for Star|2)
    def parse_number(number)
      described_class.parse(wikitext, set_code: 'B3a', set_name: 'Paradox Drive',
                                      row: { 'number' => number, 'name' => 'Iron Bundle ex', 'rarity' => 'Super Rare' })
    end

    it 'keeps Super Rare when the matching caption is Super Rare' do
      expect(parse_number('081')['rarity']).to eq('Super Rare')
    end

    it 'refines to Special Illustration Rare from the caption' do
      expect(parse_number('089')['rarity']).to eq('Special Illustration Rare')
    end

    it 'defaults to Super Rare when no tabbed image matches the number' do
      expect(parse_number('999')['rarity']).to eq('Super Rare')
    end

    it 'stays Super Rare for a single-printing card with no tabbed images' do
      plain = "{{TCG Card Infobox/Pokémon/Pocket\n|en name=Lone {{TCGP Icon|ex}}\n|type=Water\n|hp=130\n}}"
      card = described_class.parse(plain, set_code: 'B3a', set_name: 'Paradox Drive',
                                          row: { 'number' => '050', 'name' => 'Lone ex', 'rarity' => 'Super Rare' })
      expect(card['rarity']).to eq('Super Rare')
    end

    it 'leaves non-Star|2 rarities untouched' do
      card = described_class.parse(wikitext, set_code: 'B3a', set_name: 'Paradox Drive',
                                             row: { 'number' => '013', 'name' => 'Iron Bundle ex', 'rarity' => 'Double Rare' })
      expect(card['rarity']).to eq('Double Rare')
    end
  end

  describe 'promo rarity' do
    def parse_for(set_code)
      described_class.parse("{{TCG Card Infobox/Pokémon/Pocket\n|en name=X\n|type=Water\n|hp=60\n}}",
                            set_code: set_code, set_name: set_code,
                            row: { 'number' => '001', 'name' => 'X', 'rarity' => nil })
    end

    it 'labels promo-set cards (no rarity symbol) as Promo' do
      expect(parse_for('Promo-A')['rarity']).to eq('Promo')
      expect(parse_for('Promo-B')['rarity']).to eq('Promo')
    end

    it 'leaves a non-promo card with no rarity as nil' do
      expect(parse_for('B3a')['rarity']).to be_nil
    end
  end

  describe 'boosters from the expansion entry matching the set being pulled' do
    let(:wikitext) do
      <<~WIKI
        {{TCG Card Infobox/Pokémon/Pocket
        |en name=Pikachu
        |type=Lightning
        |hp=60
        |expansions=
        {{TCG Card Infobox/Expansion Header/Pocket|Genetic Apex}}
        {{TCG Card Infobox/Expansion Entry/Pocket|number=094/226|pack=Pikachu|rarity=Diamond}}
        {{TCG Card Infobox/Expansion Header/Pocket|Other Set}}
        {{TCG Card Infobox/Expansion Entry/Pocket|number=001/100|pack=Mewtwo|rarity=Diamond}}
        }}
      WIKI
    end

    it 'selects the pack for the set being pulled (not another printing)' do
      card = described_class.parse(wikitext, set_code: 'A1', set_name: 'Genetic Apex',
                                             row: { 'number' => '094', 'name' => 'Pikachu', 'rarity' => 'Diamond' })
      expect(card['boosters']).to eq(['Pikachu'])
    end

    it 'keeps "Any" as-is (expanded to the full roster later, at pull time)' do
      any = wikitext.sub('pack=Pikachu', 'pack=Any')
      card = described_class.parse(any, set_code: 'A1', set_name: 'Genetic Apex',
                                        row: { 'number' => '094', 'name' => 'Pikachu', 'rarity' => 'Diamond' })
      expect(card['boosters']).to eq(['Any'])
    end
  end
end
