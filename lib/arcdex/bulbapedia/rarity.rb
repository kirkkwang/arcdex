# frozen_string_literal: true

module Arcdex
  module Bulbapedia
    # Maps Bulbapedia's {{Rar/TCGP|symbol|count}} (e.g. Diamond|1, Star|2) to the
    # official Pokémon TCG Pocket rarity name.
    #
    # Star|2 covers both "Super Rare" and "Special Illustration Rare" — they share
    # the two-star symbol and differ only by a rainbow border the template doesn't
    # encode, so we use the more common "Super Rare".
    module Rarity
      MAP = {
        %w[Diamond 1] => 'Common',
        %w[Diamond 2] => 'Uncommon',
        %w[Diamond 3] => 'Rare',
        %w[Diamond 4] => 'Double Rare',
        %w[Star 1] => 'Illustration Rare',
        %w[Star 2] => 'Super Rare',
        %w[Star 3] => 'Immersive Rare',
        %w[Shiny 1] => 'Shiny Rare',
        %w[Shiny 2] => 'Shiny Super Rare',
        %w[Crown 1] => 'Ultra Rare'
      }.freeze

      module_function

      # symbol + count -> rarity name; falls back to the raw symbol for any
      # unmapped combo so something sensible still shows. Some sets omit the
      # count (e.g. {{rar/TCGP|Crown}}), which means 1.
      def name(symbol, count = nil)
        return nil if symbol.nil?

        symbol = symbol.to_s.strip
        count = count.to_s.strip
        count = '1' if count.empty?
        MAP.fetch([symbol, count], symbol)
      end
    end
  end
end
