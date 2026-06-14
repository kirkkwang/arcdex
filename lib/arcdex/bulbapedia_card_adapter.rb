# frozen_string_literal: true

require_relative 'base_card_adapter'

module Arcdex
  # Adapter for Pokémon TCG Pocket cards sourced from Bulbapedia.  Reads the
  # normalized hash produced at pull time (lib/arcdex/bulbapedia/*), so it stays
  # a thin field-mapper like the other adapters.  Handles both the set-level
  # record (has a "cards" array) and individual card records.
  class BulbapediaCardAdapter < BaseCardAdapter
    # Downcased to match the card id prefix (b3a-001) and the existing TCGdex
    # convention, so component parent links and the IIIF manifest resolve.
    def set_id
      record['id'].downcase
    end

    def set_name
      record['name']
    end

    def series
      code = record['id'].to_s
      # Promo-A/Promo-B group with their letter series (A/B), matching TCGdex.
      letter = code.start_with?('Promo-') ? code[6] : code[0]
      letter && "#{letter.upcase} Series"
    end

    def printed_total
      record['printed_total']
    end

    def total
      record['total']
    end

    def release_date
      record['release_date']
    end

    def updated_at
      release_date # no price data; reuse release date like TcgDexCardAdapter
    end

    def child_component_count
      record.fetch('cards', []).size
    end

    def has_online_content?
      true
    end

    def game
      'Pokémon TCG Pocket'
    end

    def legalities
      nil
    end

    def ptcgo_code
      nil
    end

    def tcgplayer
      nil
    end

    def tcgplayer_updated_at
      nil
    end

    def symbol_url
      "https://images.arcdex.dev/#{set_id}-symbol.webp" # set_id is already downcased
    end

    def logo_url
      "https://images.arcdex.dev/#{set_id}-logo.webp"
    end

    # ---- card-level ----
    def id
      record['id'].downcase
    end

    def supertype
      record['supertype']
    end

    def subtypes
      record['subtypes'] || []
    end

    def level
      nil
    end

    def hp
      record['hp']
    end

    def types
      record['types'] || []
    end

    def evolves_from
      record['evolves_from']
    end

    def evolves_to
      []
    end

    def abilities
      record['abilities']
    end

    def abilities_json
      abilities&.to_json
    end

    def ability_name(index)
      abilities&.dig(index, 'name')
    end

    def ability_text(index)
      abilities&.dig(index, 'effect')
    end

    def ability_type(index)
      abilities&.dig(index, 'type')
    end

    def attacks
      record['attacks']
    end

    def attacks_json
      attacks&.to_json
    end

    def attack_name(index)
      attacks&.dig(index, 'name')
    end

    def attack_cost(index)
      attacks&.dig(index, 'cost') || []
    end

    def attack_converted_energy_cost(index)
      attack_cost(index).size
    end

    def attack_damage(index)
      attacks&.dig(index, 'damage')
    end

    def attack_text(index)
      attacks&.dig(index, 'effect')
    end

    def weaknesses
      record['weaknesses']
    end

    def weaknesses_json
      weaknesses&.to_json
    end

    def weakness_type(index)
      weaknesses&.dig(index, 'type')
    end

    def weakness_value(index)
      weaknesses&.dig(index, 'value')
    end

    def retreat_cost
      cost = record['retreat'].to_i
      cost.zero? ? nil : Array.new(cost, 'Colorless').join(', ')
    end

    def converted_retreat_cost
      record['retreat'].to_i
    end

    def number
      record['number'].to_i
    end

    def artist
      record['illustrator']
    end

    def rarity
      record['rarity']
    end

    def regulation_mark
      nil
    end

    def flavor_text
      record['flavor_text']
    end

    def national_pokedex_numbers
      record['national_pokedex_numbers'] || []
    end

    def legalities_json
      nil
    end

    def boosters
      record['boosters'] || []
    end

    # ---- images (R2 webp) ----
    def images_json
      if record.key?('cards')
        { 'symbol' => symbol_url, 'logo' => logo_url }.to_json
      else
        { 'small' => small_image, 'large' => large_image }.to_json
      end
    end

    def small_image
      image_url
    end

    def large_image
      image_url
    end

    def image_url
      "https://images.arcdex.dev/#{id}.webp"
    end

    def tcg_player_price_url
      nil
    end

    def tcgplayer_prices
      nil
    end

    def cardmarket
      nil
    end

    def cardmarket_url
      nil
    end

    def cardmarket_avg7_price
      nil
    end

    def cardmarket_updated_at
      nil
    end

    def cardmarket_prices_json
      nil
    end
  end
end
