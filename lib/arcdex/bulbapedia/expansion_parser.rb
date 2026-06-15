# frozen_string_literal: true

require 'date'
require_relative 'wikitext'
require_relative 'rarity'

module Arcdex
  module Bulbapedia
    # Parse a TCG Pocket expansion page ("{SetName} (TCG Pocket)") into set-level
    # fields plus the card-list rows used to enumerate and fetch each card.
    class ExpansionParser
      include Wikitext
      include Rarity

      # Bulbapedia files promo logos as "PA"/"PB", but the canonical id follows
      # the Google Drive image filenames (PROMO-A-### -> promo-a-###), so the set
      # code is "Promo-A"/"Promo-B" (also Bulbapedia's expansion page name).
      PROMO_CODE_ALIASES = { 'PA' => 'Promo-A', 'PB' => 'Promo-B' }.freeze

      def self.parse(wikitext)
        new(wikitext).parse
      end

      def initialize(wikitext)
        @wt = wikitext
      end

      def parse
        {
          'id' => set_code,
          'name' => infobox['setname'],
          'release_date' => release_date,
          'printed_total' => printed_total,
          'total' => total,
          'rows' => rows
        }
      end

      private

      attr_reader :wt

      def infobox
        @infobox ||= template(wt, 'TCGPocketExpansionInfobox') || {}
      end

      # "B3a Set Logo EN.png" -> "B3a"; "PA Set Logo EN.png" -> "Promo-A"
      def set_code
        code = infobox['setlogo'].to_s.split(/\s+/).first
        code && PROMO_CODE_ALIASES.fetch(code, code)
      end

      def release_date
        Date.parse(infobox['release'].to_s).strftime('%Y-%m-%d')
      rescue ArgumentError, TypeError
        nil
      end

      # "109 (74 + 35 secret)" -> total 109, printed 74; "74" -> both 74.
      def printed_total
        cards = infobox['cards'].to_s
        m = cards.match(/\d+\s*\(\s*(\d+)/)
        return m[1].to_i if m

        cards[/\d+/]&.to_i
      end

      def total
        infobox['cards'].to_s[/\d+/]&.to_i
      end

      # Rows from the "Card list" table only (avoids TCG ID links in Trivia, etc.).
      def rows
        card_list_section.each_line.filter_map do |line|
          next unless line.include?('{{TCG ID|')

          # TCG ID has 3 params (Set|Name|Number) or 4 for ex cards
          # (Set|Display Name|Number|BaseSpecies) — capture the first three.
          id_m = line.match(/\{\{TCG ID\|([^|}]+)\|([^|}]+)\|([^|}]+?)(?:\||\}\})/)
          next unless id_m

          # Require the leading table cell ("| 001/074 ||") so a stray {{TCG ID}}
          # in a footnote/legend line within the section isn't taken as a row.
          number_cell = line.match(/^\|\s*([^|]+?)\s*\|\|/)
          next unless number_cell

          type_m = line.match(/\{\{TCG Icon\|([^|}]+)\}\}/)
          # {{Rar/TCGP|<symbol>|<count>}} -> mapped to the official rarity name.
          # First letter is case-insensitive in MediaWiki and sets vary (Rar/rar);
          # the count is optional (e.g. crowns are written {{rar/TCGP|Crown}}). No
          # `}}` anchor, so any extra params are ignored rather than dropping the match.
          rarity_m = line.match(/\{\{[Rr]ar\/TCGP\|([^|}]+)(?:\|([^|}]+))?/)

          {
            'number' => number_cell[1].split('/').first.strip, # "001/074" -> "001"
            'name' => id_m[2].strip,
            'local_number' => id_m[3].strip,
            'type' => type_m && type_m[1].strip,
            'rarity' => rarity_m && name(rarity_m[1], rarity_m[2])
          }
        end
      end

      # The "Card list" heading through just before the next level-2 heading
      # (or end of page). `/m` so `.` spans newlines; the lookahead stops the
      # match at the next "== ... ==" section.
      def card_list_section
        wt[/==\s*Card list\s*==.*?(?=\n==[^=]|\z)/m] || ''
      end
    end
  end
end
