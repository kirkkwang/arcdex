# OVERRIDE Blacklight v8.9.0 to support exclude facets to add a configuration called `excludable` to
#   facets which defaults to off.  To turn on exclude facets, add `excludable: true`.

module Blacklight
  module Configuration::FacetFieldDecorator
    def normalize!(blacklight_config = nil)
      super

      self.excludable = true if excludable.is_a? TrueClass

      self
    end
  end
end

Blacklight::Configuration::FacetField.prepend(Blacklight::Configuration::FacetFieldDecorator)
