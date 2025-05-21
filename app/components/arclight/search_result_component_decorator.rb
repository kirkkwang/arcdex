# OVERRIDE Arclight v2.0.0.alpha to add the thumbnail image instead of a SVG icon

module Arclight
  module SearchResultComponentDecorator
    def icon
      link_to(
        image_tag(@document.icon_url, width: '100%', alt: "#{@document.normalized_title} thumbnail", loading: 'lazy'),
        solr_document_path(@document.id)
      )
    end
  end
end

Arclight::SearchResultComponent.prepend(Arclight::SearchResultComponentDecorator)
