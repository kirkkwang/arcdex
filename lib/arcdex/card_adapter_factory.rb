require_relative 'tcg_dex_card_adapter'
require_relative 'pokemon_tcg_io_card_adapter'

module Arcdex
  class CardAdapterFactory
    class << self
      def call(record)
        if pocket?(record)
          Arcdex::TcgDexCardAdapter.new(record)
        else
          Arcdex::PokemonTcgIoCardAdapter.new(record)
        end
      end

      private

      def pocket?(record)
        record.is_a?(Hash) && !record.fetch('images', {}).values.first&.include?('pokemontcg')
      end
    end
  end
end
