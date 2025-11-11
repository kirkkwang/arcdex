require_relative 'base_card_adapter'

module Arcdex
  class TcgDexCardAdapter < BaseCardAdapter
    # rubocop:disable Style/SafeNavigationChainLength
    def set_id
      record.fetch('cards', nil)&.first&.fetch('set', nil)&.fetch('id', nil)&.downcase
    end

    def set_name
      record.fetch('cards', nil)&.first&.fetch('set')&.fetch('name', nil)
    end

    def series
      if record.fetch('cards', nil).nil?
        "#{record['id'][0].upcase} Series"
      else
        "#{record.fetch('cards').first['id'][0].upcase} Series"
      end
    end

    def printed_total
      record.fetch('cards', nil)&.first&.fetch('set', nil)&.fetch('cardCount', nil)&.fetch('official', nil)
    end

    def total
      record.fetch('cards', nil)&.first&.fetch('set', nil)&.fetch('cardCount', nil)&.fetch('total', nil)
    end

    def legalities
      record.fetch('cards', nil)&.first&.fetch('legal', {})
    end

    def ptcgo_code
      nil
    end

    def release_date
      record.fetch('releaseDate', nil)
    end

    def updated_at
      release_date # No price info so we'll just use the release date
    end

    def images_json
      {
        'symbol' => symbol_url,
        'logo' =>  logo_url
      }.to_json
    end

    def symbol_url
      image = record.fetch('symbol', nil)
      image = "https://assets.tcgdex.net/univ/tcgp/#{record.fetch('cards', nil)&.first&.fetch('set', nil)&.fetch('id', nil)}/symbol" if image.nil?
      image + '.png'
    end

    def logo_url
      image = record.fetch('logo', nil)
      image = "https://assets.tcgdex.net/en/tcgp/#{record.fetch('cards', nil)&.first&.fetch('set', nil)&.fetch('id', nil)}/logo" if image.nil?
      image + '.png'
    end

    def tcgplayer
      nil
    end

    def tcgplayer_updated_at
      nil
    end

    def id
      record['id'].downcase
    end

    def child_component_count
      record.fetch('cards', []).size
    end

    def supertype
      category = record.fetch('category', nil)

      if category == 'Pokemon'
        'Pokémon'
      else
        category
      end
    end

    def subtypes
      Array(record.fetch('stage', '').gsub(/([a-zA-Z])(\d)/, '\1 \2'))
    end

    def level
      nil
    end

    def hp
      record.fetch('hp', nil)&.to_i
    end

    def types
      record.fetch('types', [])
    end

    def evolves_from
      record.fetch('evolveFrom', nil)
    end

    def evolves_to
      []
    end

    def abilities_json
      abilities.to_json
    end

    def abilities
      record.fetch('abilities', [])
    end

    def ability_name(index)
      abilities[index]&.fetch('name', nil)
    end

    def ability_text(index)
      abilities[index]&.fetch('effect', nil)
    end

    def ability_type(index)
      abilities[index]&.fetch('type', nil)
    end

    def attacks_json
      attacks.to_json
    end

    def attacks
      record.fetch('attacks', [])
    end

    def attack_name(index)
      attacks[index]&.fetch('name', nil)
    end

    def attack_cost(index)
      attacks[index]&.fetch('cost', [])
    end

    def attack_converted_energy_cost(index)
      attack_cost(index)&.size
    end

    def attack_damage(index)
      attacks[index]&.fetch('damage', nil)
    end

    def attack_text(index)
      attacks[index]&.fetch('effect', nil)
    end

    def weaknesses_json
      weaknesses.to_json
    end

    def weaknesses
      record.fetch('weaknesses', [])
    end

    def weakness_type(index)
      weaknesses[index]&.fetch('type', nil)
    end

    def weakness_value(index)
      weaknesses[index]&.fetch('value', nil)
    end

    def retreat_cost
      cost = record.fetch('retreat', nil).to_i
      if cost.zero?
        []
      else
        Array.new(cost, 'Colorless').join(', ')
      end
    end

    def converted_retreat_cost
      record.fetch('retreat', nil).to_i
    end

    def number
      record.fetch('localId', nil).to_i
    end

    def artist
      record.fetch('illustrator', nil)
    end

    def rarity
      record.fetch('rarity', nil)
    end

    def regulation_mark
      record.fetch('regulationMark', nil)
    end

    def flavor_text
      record.fetch('description', nil)
    end

    def national_pokedex_numbers
      # TCGDex does not provide this data but maybe we need some sort of lookup 🤔
      []
    end

    def legalities_json
      legalities.to_json
    end

    def legalities
      {}
    end

    def images_json
      images.to_json
    end

    def images
      {
        'small' => small_image,
        'large' => large_image
      }
    end

    def small_image
      record.fetch('image', '') + '/low.png'
    end

    def large_image
      "https://images.arcdex.dev/#{id}.png"
    end

    def tcg_player_price_url
      nil # no data for Pokemon TCG Pocket cards
    end

    def tcgplayer_prices
      nil # no data for Pokemon TCG Pocket cards
    end

    def cardmarket
      nil # no data for Pokemon TCG Pocket cards
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
