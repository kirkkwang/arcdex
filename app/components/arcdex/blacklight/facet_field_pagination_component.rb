# frozen_string_literal: true

module Arcdex
  module Blacklight
    # Adds a button for a facet's configured json sort (e.g. 'release desc') to the
    # A-Z and Numerical buttons, which are the only sorts upstream knows about.
    class FacetFieldPaginationComponent < ::Blacklight::FacetFieldPaginationComponent
      # @return [Hash{String => String}] facet.sort value => button label
      def sort_options
        options = {}
        options[json_sort] = t("blacklight.search.facets.sort.#{json_sort.split.first}") if json_sort
        options['index'] = t('blacklight.search.facets.sort.index')
        options['count'] = t('blacklight.search.facets.sort.count')
        options
      end

      def active_sort?(sort)
        @facet_field.paginator.sort == sort
      end

      private

      def json_sort
        json = @facet_field.facet_field.json
        json[:sort] if json.respond_to?(:key?)
      end
    end
  end
end
