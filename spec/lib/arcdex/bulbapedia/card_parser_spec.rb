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

    it 'treats an "Any" pack as no specific booster' do
      any = wikitext.sub('pack=Pikachu', 'pack=Any')
      card = described_class.parse(any, set_code: 'A1', set_name: 'Genetic Apex',
                                        row: { 'number' => '094', 'name' => 'Pikachu', 'rarity' => 'Diamond' })
      expect(card['boosters']).to eq([])
    end
  end
end
