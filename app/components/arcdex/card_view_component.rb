module Arcdex
  class CardViewComponent < ::Arclight::UpperMetadataLayoutComponent
    attr_reader :field, :document

    def initialize(field:, label_class: 'col-md-3 offset-md-1', value_class: 'col-md-8', **)
      super(field:, label_class:, value_class:)

      @document = field.document
    end

    def image
      document.image_html.html_safe
    end
  end
end
