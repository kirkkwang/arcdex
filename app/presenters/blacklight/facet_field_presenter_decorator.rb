# OVERRIDE Blacklight 8.11.0 to keep a facet card open if there are excluded values

module Blacklight
  module FacetFieldPresenterDecorator
    def collapsed?
      super && !search_state.params[:f]&.keys&.include?("-#{facet_field.key}")
    end
  end
end

Blacklight::FacetFieldPresenter.prepend(Blacklight::FacetFieldPresenterDecorator)
