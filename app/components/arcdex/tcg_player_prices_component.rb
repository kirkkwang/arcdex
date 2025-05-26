module Arcdex
  class TcgPlayerPricesComponent < ::Arclight::IndexMetadataFieldComponent
    attr_reader :field
    delegate :document, :field_config, to: :field
    delegate :tcg_player_price_updated_at, :tcg_player_prices_object, to: :document

    private

    def prices_object
      @prices_object ||= tcg_player_prices_object
    end

    def all_price_types
      prices_object.values.first.keys
    end

    def last_updated_at
      "#{t('.last_updated')}: #{tcg_player_price_updated_at}"
    end

    def format_price(price)
      return '-' if price.nil?
      "$#{'%.2f' % price}"
    end
  end
end
