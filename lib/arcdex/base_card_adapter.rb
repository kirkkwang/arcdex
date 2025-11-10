module Arcdex
  class BaseCardAdapter
    attr_reader :record

    def initialize(record)
      @record = record
    end

    def set_id
      raise NoMethodError, 'Subclasses must implement the set_id method'
    end

    def set_name
      raise NoMethodError, 'Subclasses must implement the set_name method'
    end

    def series
      raise NoMethodError, 'Subclasses must implement the series method'
    end

    def printed_total
      raise NoMethodError, 'Subclasses must implement the printed_total method'
    end

    def total
      raise NoMethodError, 'Subclasses must implement the total method'
    end

    def legalities
      raise NoMethodError, 'Subclasses must implement the legalities method'
    end

    def ptcgo_code
      raise NoMethodError, 'Subclasses must implement the ptcgo_code method'
    end

    def release_date
      raise NoMethodError, 'Subclasses must implement the release_date method'
    end

    def updated_at
      raise NoMethodError, 'Subclasses must implement the updated_at method'
    end

    def images_json
      raise NoMethodError, 'Subclasses must implement the images_json method'
    end

    def symbol_url
      raise NoMethodError, 'Subclasses must implement the symbol_url method'
    end

    def tcg_player_price_url
      raise NoMethodError, 'Subclasses must implement the tcg_player_price_url method'
    end

    def id
      raise NoMethodError, 'Subclasses must implement the id method'
    end

    def child_component_count
      raise NoMethodError, 'Subclasses must implement the child_component_count method'
    end

    def supertype
      raise NoMethodError, 'Subclasses must implement the supertype method'
    end

    def subtype
      raise NoMethodError, 'Subclasses must implement the subtype method'
    end

    def level
      raise NoMethodError, 'Subclasses must implement the level method'
    end

    def hp
      raise NoMethodError, 'Subclasses must implement the hp method'
    end

    def types
      raise NoMethodError, 'Subclasses must implement the types method'
    end

    def evolves_from
      raise NoMethodError, 'Subclasses must implement the evolves_from method'
    end

    def evolves_to
      raise NoMethodError, 'Subclasses must implement the evolves_to method'
    end

    def abilities_json
      raise NoMethodError, 'Subclasses must implement the abilities_json method'
    end

    def abilities
      raise NoMethodError, 'Subclasses must implement the abilities method'
    end

    def ability_name(index)
      raise NoMethodError, 'Subclasses must implement the ability_name method'
    end

    def ability_text(index)
      raise NoMethodError, 'Subclasses must implement the ability_text method'
    end

    def ability_type(index)
      raise NoMethodError, 'Subclasses must implement the ability_type method'
    end

    def attacks_json
      raise NoMethodError, 'Subclasses must implement the attacks_json method'
    end

    def attacks
      raise NoMethodError, 'Subclasses must implement the attacks method'
    end

    def attack_name(index)
      raise NoMethodError, 'Subclasses must implement the attack_name method'
    end

    def attack_cost(index)
      raise NoMethodError, 'Subclasses must implement the attack_cost method'
    end

    def attack_converted_energy_cost(index)
      raise NoMethodError, 'Subclasses must implement the attack_converted_energy_cost method'
    end

    def attack_damage(index)
      raise NoMethodError, 'Subclasses must implement the attack_damage method'
    end

    def attack_text(index)
      raise NoMethodError, 'Subclasses must implement the attack_text method'
    end

    def weaknesses_json
      raise NoMethodError, 'Subclasses must implement the weaknesses_json method'
    end

    def weaknesses
      raise NoMethodError, 'Subclasses must implement the weaknesses method'
    end

    def weakness_type(index)
      raise NoMethodError, 'Subclasses must implement the weakness_type method'
    end

    def weakness_value(index)
      raise NoMethodError, 'Subclasses must implement the weakness_value method'
    end

    def retreat_cost
      raise NoMethodError, 'Subclasses must implement the retreat_cost method'
    end

    def converted_retreat_cost
      raise NoMethodError, 'Subclasses must implement the converted_retreat_cost method'
    end

    def number
      raise NoMethodError, 'Subclasses must implement the number method'
    end

    def artist
      raise NoMethodError, 'Subclasses must implement the artist method'
    end

    def rarity
      raise NoMethodError, 'Subclasses must implement the rarity method'
    end

    def regulation_mark
      raise NoMethodError, 'Subclasses must implement the regulation_mark method'
    end

    def flavort_text
      raise NoMethodError, 'Subclasses must implement the flavortext method'
    end

    def national_pokedex_numbers
      raise NoMethodError, 'Subclasses must implement the national_pokedex_numbers method'
    end

    def legalities_json
      raise NoMethodError, 'Subclasses must implement the legalities_json method'
    end

    def legalities
      raise NoMethodError, 'Subclasses must implement the legalities method'
    end

    def images_json
      raise NoMethodError, 'Subclasses must implement the images_json method'
    end

    def images
      raise NoMethodError, 'Subclasses must implement the images method'
    end

    def tcg_player_price_url
      raise NoMethodError, 'Subclasses must implement the tcg_player_price_url method'
    end

    def tcgplayer_prices
      raise NoMethodError, 'Subclasses must implement the tcgplayer_prices method'
    end

    def cardmarket
      raise NoMethodError, 'Subclasses must implement the cardmarket method'
    end

    def cardmarket_url
      raise NoMethodError, 'Subclasses must implement the cardmarket_url method'
    end

    def cardmarket_avg7_price
      raise NoMethodError, 'Subclasses must implement the cardmarket_avg7_price method'
    end

    def cardmarket_updated_at
      raise NoMethodError, 'Subclasses must implement the cardmarket_updated_at method'
    end

    def cardmarket_prices_json
      raise NoMethodError, 'Subclasses must implement the cardmarket_prices_json method'
    end
  end
end
