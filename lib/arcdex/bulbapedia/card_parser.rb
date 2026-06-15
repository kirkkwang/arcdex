# frozen_string_literal: true

require_relative 'wikitext'

module Arcdex
  module Bulbapedia
    # Parse a single TCG Pocket card's wikitext into the normalized hash the
    # BulbapediaCardAdapter reads.
    class CardParser
      include Wikitext

      POKEMON_INFOBOX = 'TCG Card Infobox/Pokémon/Pocket'
      TRAINER_INFOBOX = 'TCG Card Infobox/Trainer/Pocket'

      # row: { 'number' => '001', 'name' => 'Surskit', 'rarity' => 'Diamond' }
      def self.parse(wikitext, set_code:, set_name:, row:)
        new(wikitext, set_code, set_name, row).parse
      end

      def initialize(wikitext, set_code, set_name, row)
        @wt = wikitext
        @set_code = set_code
        @set_name = set_name
        @row = row
      end

      def parse
        base = {
          '_source' => 'bulbapedia',
          'id' => "#{set_code}-#{row['number']}",
          'number' => row['number'],
          'rarity' => rarity,
          'boosters' => boosters
        }
        pokemon? ? base.merge(pokemon_fields) : base.merge(trainer_fields)
      end

      private

      attr_reader :wt, :set_code, :set_name, :row

      def pokemon?
        wt.include?("{{#{POKEMON_INFOBOX}")
      end

      def infobox
        @infobox ||= template(wt, pokemon? ? POKEMON_INFOBOX : TRAINER_INFOBOX) || {}
      end

      # The card-list row name is the clean display name (and matches the page
      # title), prefer it over the infobox en name, which composes icon templates
      # like "Mega Altaria {{TCGP Icon|Mega ex}}".
      def name
        row_name = row['name'].to_s.strip
        row_name.empty? ? clean(infobox['en name']) : row_name
      end

      # Top-level illustrator, or the first tabbed-image illustrator for cards
      # that have multiple printings/variants.
      def illustrator
        clean(infobox['illustrator']) ||
          clean(template(wt, 'TCG Card Infobox/Tabbed Image/Pocket')&.dig('illustrator'))
      end

      def pokemon_fields
        {
          'name' => name,
          'supertype' => 'Pokémon',
          'subtypes' => [clean(infobox['evo stage']), paradox_subtype, *ex_subtypes].compact,
          'hp' => infobox['hp']&.to_i,
          'types' => Array(infobox['type']).reject { |t| t.to_s.strip.empty? },
          'evolves_from' => clean(infobox['evolves from']),
          'weaknesses' => weaknesses,
          'retreat' => infobox['retreat cost'].to_i,
          'illustrator' => illustrator,
          'abilities' => abilities,
          'attacks' => attacks,
          'flavor_text' => flavor_text,
          'national_pokedex_numbers' => national_pokedex_numbers
        }
      end

      def trainer_fields
        subtype = clean(infobox['subtype'])
        {
          'name' => name,
          'supertype' => 'Trainer',
          'subtypes' => Array(subtype).reject { |s| s.to_s.strip.empty? },
          'illustrator' => illustrator,
          # Trainer rules text lives in TCGTrainerText; mirror TCGdex which surfaced
          # trainer effect text through flavor_text.
          'flavor_text' => trainer_effect
        }
      end

      # Paradox mechanic, marked by a {{Cardtext/Ancient|Future/Pocket}} template
      # (e.g. Iron Moth = Future, Raging Bolt = Ancient). Surfaced as a subtype.
      def paradox_subtype
        return 'Ancient' if wt.include?('{{Cardtext/Ancient/Pocket')
        return 'Future' if wt.include?('{{Cardtext/Future/Pocket')

        nil
      end

      # "ex" Pokémon carry a {{TCGP Icon|ex}} marker in the infobox name; Mega ex
      # cards use {{TCGP Icon|Mega ex}} and count as both MEGA and ex (matching
      # how the main Pokémon TCG splits the subtypes).
      def ex_subtypes
        name = infobox['en name'].to_s
        return %w[MEGA ex] if name.match?(/\{\{TCGP Icon\|Mega ex\}\}/i)
        return ['ex'] if name.match?(/\{\{TCGP Icon\|ex\}\}/i)

        []
      end

      def weaknesses
        type = clean(infobox['weakness'])
        return nil if type.nil? || type.casecmp?('none')

        # Pokémon TCG Pocket weakness is always a flat +20 damage bonus.
        [{ 'type' => type, 'value' => '+20' }]
      end

      def attacks
        list = templates(wt, 'Cardtext/Attack/Pocket').map do |a|
          damage = a['damage'].to_s.strip
          {
            'name' => clean(a['name']),
            'cost' => energy(a['cost']),
            'damage' => (damage.empty? ? nil : damage), # nil (not "") so the config skips it, matching TCGdex
            'effect' => clean(a['effect'])
          }
        end
        list.empty? ? nil : list
      end

      def abilities
        list = templates(wt, 'Cardtext/Ability/Pocket').map do |a|
          {
            'name' => clean(a['name']),
            'effect' => clean(a['effect']),
            'type' => clean(a['type'])
          }
        end
        list.empty? ? nil : list
      end

      def trainer_effect
        clean(template(wt, 'TCGTrainerText')&.dig('effect'))
      end

      def flavor_text
        clean(carddex['dex'])
      end

      def national_pokedex_numbers
        digits = carddex['ndex'].to_s[/\d+/]
        digits ? [digits.to_i] : []
      end

      # Parsed once; read by both flavor_text and national_pokedex_numbers.
      def carddex
        @carddex ||= template(wt, 'Carddex/Pocket') || {}
      end

      # The set list maps the rarity from the {{Rar/TCGP}} symbol, but Star|2 is
      # ambiguous (Super Rare and Special Illustration Rare share the symbol).
      # Disambiguate from the card page's per-printing tabbed-image caption,
      # matched to this card's number; otherwise keep the set-list value.
      def rarity
        base = row['rarity']
        # Promo cards carry no rarity symbol on Bulbapedia; mirror the main TCG's "Promo".
        base ||= 'Promo' if promo_set?
        return base unless base == 'Super Rare'

        tab_caption_for(row['number'])&.match?(/special illustration/i) ? 'Special Illustration Rare' : 'Super Rare'
      end

      def promo_set?
        set_code.to_s.downcase.start_with?('promo')
      end

      # The `tab caption` of the tabbed image whose filename ends in this number
      # (e.g. "...ParadoxDrive89.png" -> the 089 printing's caption).
      def tab_caption_for(number)
        target = number.to_i
        return nil if target.zero? # no real card is numbered 0; avoids matching numberless filenames

        image = templates(wt, 'TCG Card Infobox/Tabbed Image/Pocket').find do |tab|
          digits = tab['image'].to_s[/(\d+)\.\w+\z/, 1]
          digits && digits.to_i == target
        end
        clean(image&.dig('tab caption'))
      end

      # The card's pack within THIS set (from its expansion entry). " Any" is kept
      # as-is here and expanded to the set's full booster roster at pull time
      # (the roster is a cross-card aggregate); a card with no pack -> [].
      def boosters
        entry = expansion_entries.find do |e|
          e[:set_name] == set_name && e[:number].to_s.split('/').first == row['number']
        end
        pack = (entry && entry[:pack]).to_s.strip
        pack.empty? ? [] : [pack]
      end

      def expansion_entries
        @expansion_entries ||= build_expansion_entries
      end

      def build_expansion_entries
        header = '{{TCG Card Infobox/Expansion Header/Pocket'
        entry = '{{TCG Card Infobox/Expansion Entry/Pocket'
        points = []
        [[header, :header], [entry, :entry]].each do |needle, type|
          i = 0
          while (pos = wt.index(needle, i))
            points << [pos, type]
            i = pos + needle.length
          end
        end
        points.sort_by!(&:first)

        entries = []
        current_set = nil
        points.each do |pos, type|
          stop = matching_close(wt, pos)
          next if stop.nil?

          fields = params(wt[(pos + 2)...(stop - 2)])
          if type == :header
            current_set = fields['_positional']&.first
          else
            entries << { set_name: current_set, number: fields['number'], pack: fields['pack'] }
          end
        end
        entries
      end
    end
  end
end
