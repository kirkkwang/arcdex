module Arcdex
  class CardmarketPricesComponent < ::Arclight::IndexMetadataFieldComponent
    attr_reader :field
    delegate :document, :field_config, to: :field
    delegate :cardmarket_price_updated_at, :cardmarket_prices_object, to: :document

    private

    def prices_object
      @prices_object ||= cardmarket_prices_object
    end

    def all_price_types
      prices_object.keys
    end

    def last_updated_at
      "#{t('.last_updated')}: #{cardmarket_price_updated_at}"
    end

    def format_price(price)
      return '-' if price.nil?
      "#{'%.2f' % price} €"
    end
  end
end
