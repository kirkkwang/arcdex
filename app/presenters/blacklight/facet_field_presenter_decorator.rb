# OVERRIDE Blacklight 8.11.0 to keep a facet card open if there are excluded values
#   and to not show the 'more' link on the advanced search form since we're not
#   limiting it there

module Blacklight
  module FacetFieldPresenterDecorator
    def collapsed?
      super && !search_state.params[:f]&.keys&.include?("-#{facet_field.key}")
    end

    def facet_limit
      return if view_context.params[:action] == 'advanced_search'

      super
    end

    def paginator
      return unless display_facet

      f = search_state.params[:f]
      return super unless f

      excluded_items = []
      excluded_items = excluded_facet_items(f) if excluded_param(f)

      return super if excluded_items.empty?

      display_facet.items.unshift(*excluded_items) unless display_facet.items.first&.value == excluded_items.first&.value

      super
    end

    private

    def excluded_param(f)
      f.key?(excluded_facet_key)
    end

    def excluded_facet_items(f)
      excluded_values = f[excluded_facet_key]
      return [] unless excluded_values

      excluded_values.map { |value| Blacklight::Solr::Response::Facets::FacetItem.new(value) }
    end

    def excluded_facet_key
      "-#{facet_field.key}"
    end
  end
end

Blacklight::FacetFieldPresenter.prepend(Blacklight::FacetFieldPresenterDecorator)
