# OVERRIDE Arclight 2.0.0.alpha to disable the heading

module Arclight
  module MetadataSectionComponentDecorator
    def initialize(section:, presenter:, metadata_attr: {}, classes: %w[row dl-invert], heading: false)
      super

      @heading = false
    end
  end
end

Arclight::MetadataSectionComponent.prepend(Arclight::MetadataSectionComponentDecorator)
