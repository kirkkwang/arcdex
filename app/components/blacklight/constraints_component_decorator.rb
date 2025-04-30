# OVERRIDE Blacklight v8.9.0 to support exclude facets by giving us instances of
#   `Arcdex::ExcludeFacetItemPresenter` for specific logic

module Blacklight
  module ConstraintsComponentDecorator
    private

    def facet_item_presenters
      return to_enum(:facet_item_presenters) unless block_given?

      filter_presenters = []
      @search_state.filters.map do |facet|
        facet.each_value do |val|
          next if val.blank?

          if val.is_a?(Array)
            filter_presenters << inclusive_facet_item_presenter(facet.config, val, facet.key) if val.any?(&:present?)
          else
            filter_presenters <<  facet_item_presenter(facet.config, val, facet.key)
          end
        end
      end

      exclude_filter_presenters = []
      f = @search_state.params[:f]
      if f
        f.select { |key, _| key.starts_with?("-") }.each do |k, v|
          v.each do |val|
            exclude_filter_presenters << exclude_facet_item_presenter(@search_state.blacklight_config.facet_fields[k[1..]], val, k)
          end
        end
      end

      (filter_presenters + exclude_filter_presenters).each { |presenter| yield presenter }
    end

    def exclude_facet_item_presenter(facet_config, facet_item, facet_field)
      ::Arcdex::ExcludeFacetItemPresenter.new(facet_item, facet_config, helpers, facet_field)
    end
  end
end

Blacklight::ConstraintsComponent.prepend(Blacklight::ConstraintsComponentDecorator)
