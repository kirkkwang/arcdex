# OVERRIDE Blacklight v9.2.1 to support exclude facets by appending constraint presenters
#   wrapping `Arcdex::ExcludeFacetItemPresenter` for specific logic

module Blacklight
  module ConstraintsComponentDecorator
    private

    def constraint_presenters(&block)
      return to_enum(:constraint_presenters) unless block

      super
      exclude_constraint_presenters.each(&block)
    end

    def exclude_constraint_presenters
      f = @search_state.params[:f]
      return [] unless f

      f.select { |key, _| key.starts_with?('-') }.flat_map do |key, values|
        facet_config = @search_state.blacklight_config.facet_fields[key[1..]]
        field_label = helpers.facet_field_presenter(facet_config, {}).label

        values.map do |value|
          facet_config.constraint_presenter.new(
            facet_item_presenter: ::Arcdex::ExcludeFacetItemPresenter.new(value, facet_config, helpers, key),
            field_label:
          )
        end
      end
    end
  end
end

Blacklight::ConstraintsComponent.prepend(Blacklight::ConstraintsComponentDecorator)
