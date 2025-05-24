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
  end
end

Blacklight::FacetFieldPresenter.prepend(Blacklight::FacetFieldPresenterDecorator)
