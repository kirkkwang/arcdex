# OVERRIDE Arclight v2.0.0.alpha to remove @heading and render our own custom html

module Arcdex
  class MetadataSectionComponent < ::Arclight::MetadataSectionComponent
    def initialize(section:, presenter:, metadata_attr: {}, classes: %w[row dl-invert], heading: false)
      super

      @heading = false
    end
  end
end
