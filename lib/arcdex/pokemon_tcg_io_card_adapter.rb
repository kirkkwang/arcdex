require_relative 'base_card_adapter'

module Arcdex
  class PokemonTcgIoCardAdapter < BaseCardAdapter
    def initialize(record)
      super(record.is_a?(Array) ? record : [record])
    end

    def set_id
      record.first.fetch('set')&.fetch('id', nil)
    end

    def has_online_content?
      false # pokemontcg.io does not support Pocket cards
    end

    def set_name
      record.first.fetch('set')&.fetch('name', nil)
    end

    def series
      record.first&.fetch('set', nil)&.fetch('series', nil)
    end

    def printed_total
      record.first.fetch('set')&.fetch('printedTotal', nil)
    end

    def total
      record.first.fetch('set')&.fetch('total', nil)
    end

    def legalities
      record.first.fetch('set')&.fetch('legalities', nil)
    end

    def ptcgo_code
      record.first.fetch('set')&.fetch('ptcgoCode', nil)
    end

    def release_date
      record.first.fetch('set')&.fetch('releaseDate', nil)&.gsub('/', '-')
    end

    def updated_at
      record.first.fetch('set', nil)&.fetch('updatedAt', nil)
    end

    def images_json
      record.first.fetch('set', nil)&.fetch('images', nil)&.to_json
    end

    def symbol_url
      record.first.fetch('set', nil)&.fetch('images', nil)&.fetch('symbol', nil)
    end

    def logo_url
      record.first.fetch('set', nil)&.fetch('images', nil)&.fetch('logo', nil)
    end

    def tcgplayer
      record.first.fetch('tcgplayer', nil)
    end

    def tcgplayer_updated_at
      tcgplayer&.fetch('updatedAt', nil)&.gsub('/', '-')
    end

    def id
      record.first['id']
    end

    def child_component_count
      record.size
    end

    def supertype
      record.first.fetch('supertype', nil)
    end

    def subtypes
      record.first.fetch('subtypes', [])
    end

    def level
      record.first.fetch('level', nil)
    end

    def hp
      record.first.fetch('hp', nil)&.to_i
    end

    def types
      record.first.fetch('types', [])
    end

    def evolves_from
      record.first.fetch('evolvesFrom', nil)
    end

    def evolves_to
      record.first.fetch('evolvesTo', [])
    end

    def abilities_json
      abilities.to_json
    end

    def abilities
      record.first.fetch('abilities', [])
    end

    def ability_name(index)
      abilities[index]&.fetch('name', nil)
    end

    def ability_text(index)
      abilities[index]&.fetch('text', nil)
    end

    def ability_type(index)
      abilities[index]&.fetch('type', nil)
    end

    def attacks_json
      attacks.to_json
    end

    def attacks
      record.first.fetch('attacks', [])
    end

    def attacks_json
      attacks.to_json
    end

    def attacks
      record.first.fetch('attacks', [])
    end

    def attack_name(index)
      attacks[index]&.fetch('name', nil)
    end

    def attack_cost(index)
      attacks[index]&.fetch('cost', [])
    end

    def attack_converted_energy_cost(index)
      attacks[index]&.fetch('convertedEnergyCost', nil)
    end

    def attack_damage(index)
      attacks[index]&.fetch('damage', nil)
    end

    def attack_text(index)
      attacks[index]&.fetch('text', nil)
    end

    def weaknesses_json
      weaknesses.to_json
    end

    def weaknesses
      record.first.fetch('weaknesses', [])
    end

    def weakness_type(index)
      weaknesses[index]&.fetch('type', nil)
    end

    def weakness_value(index)
      weaknesses[index]&.fetch('value', nil)
    end

    def retreat_cost
      record.first.fetch('retreatCost', []).join(', ')
    end

    def converted_retreat_cost
      record.first.fetch('convertedRetreatCost', nil)
    end

    def number
      # Revert when https://api.pokemontcg.io/v2/cards/zsv10pt5-80 number gets corrected
      if id == 'zsv10pt5-80'
        80
      else
        record.first.fetch('number', nil)
      end
    end

    def artist
      record.first.fetch('artist', nil)
    end

    def rarity
      # Revert when https://api.pokemontcg.io/v2/cards/rsv10pt5-172 and https://api.pokemontcg.io/v2/cards/zsv10pt5-171
      # rarities gets corrected
      if id == 'rsv10pt5-172' || id == 'rsv10pt5-171'
        'Black White Rare'
      else
        record.first.fetch('rarity', nil)
      end
    end

    def regulation_mark
      record.first.fetch('regulationMark', nil)
    end

    def flavor_text
      record.first.fetch('flavorText', nil)
    end

    def national_pokedex_numbers
      record.first['nationalPokedexNumbers'] || []
    end

    def legalities_json
      legalities.to_json
    end

    def legalities
      record.first['legalities'] || {}
    end

    def images_json
      images.to_json
    end

    def images
      record.first.fetch('images', {})
    end

    def small_image
      images['small']
    end

    def large_image
      images['large']
    end

    def tcg_player_price_url
      tcgplayer&.fetch('url', nil)
    end

    def tcgplayer_prices
      tcgplayer&.fetch('prices', nil)
    end

    def cardmarket
      record.first.fetch('cardmarket', nil)
    end

    def cardmarket_url
      cardmarket&.fetch('url', nil)
    end

    def cardmarket_avg7_price
      cardmarket_prices&.fetch('avg7', nil)
    end

    def cardmarket_prices
      cardmarket&.fetch('prices', nil)
    end

    def cardmarket_updated_at
      cardmarket&.fetch('updatedAt', nil)
    end

    def cardmarket_prices_json
      cardmarket_prices&.to_json
    end

    def boosters
      nil # pokemontcg.io does not provide booster information
    end
  end
end
