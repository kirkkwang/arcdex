require_relative 'tcg_dex_card_adapter'
require_relative 'pokemon_tcg_io_card_adapter'
require_relative 'bulbapedia_card_adapter'

module Arcdex
  class CardAdapterFactory
    class << self
      def call(record)
        if bulbapedia?(record)
          Arcdex::BulbapediaCardAdapter.new(record)
        elsif pocket?(record)
          Arcdex::TcgDexCardAdapter.new(record)
        else
          Arcdex::PokemonTcgIoCardAdapter.new(record)
        end
      end

      private

      # New Pocket data carries an explicit source marker; legacy TCGdex/
      # pokemontcg.io files fall through to image-URL sniffing below.
      def bulbapedia?(record)
        record.is_a?(Hash) && record['_source'] == 'bulbapedia'
      end

      def pocket?(record)
        record.is_a?(Hash) &&
          !record.fetch('images', {}).values.first&.include?('pokemontcg') &&
          !record.fetch('images', {}).values.first&.include?('scrydex')
      end
    end
  end
end
