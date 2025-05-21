# OVERRIDE Blacklight v8.9.0 to support exclude facets, this will allow us to add a specific class
#   to the constraints to make it look different than the regular constraints

module Blacklight
  module ConstraintComponentDecorator
    def initialize(facet_item_presenter:, classes: 'filter', layout: Blacklight::ConstraintLayoutComponent)
      super

      @classes = facet_item_presenter.classes.presence || classes
    end
  end
end

Blacklight::ConstraintComponent.prepend(Blacklight::ConstraintComponentDecorator)
