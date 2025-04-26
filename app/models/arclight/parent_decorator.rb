# OVERRIDE Arclight v2.0.0.aplpha because we're using the term set instead of collection

module Arclight
  module ParentDecorator
    def collection?
      level == "set" || super
    end
  end
end

Arclight::Parent.prepend(Arclight::ParentDecorator)
