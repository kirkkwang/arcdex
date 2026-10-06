# OVERRIDE Blacklight v9.2.1 to support exclude facets, this will allow us to add a specific class
#   to the constraints to make it look different than the regular constraints

module Blacklight
  module ConstraintComponentDecorator
    def initialize(facet_item_presenter:, **)
      super

      exclude_classes = facet_item_presenter.try(:facet_item_presenter).try(:classes)
      @classes = Array(exclude_classes) if exclude_classes.present?
    end
  end
end

Blacklight::ConstraintComponent.prepend(Blacklight::ConstraintComponentDecorator)
