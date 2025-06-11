# OVERRIDE Blacklight v8.11.0 to render custom thumbnail with zoomable image

module Arcdex
  module Blacklight
    module Document
      class ThumbnailComponent < ::Blacklight::Document::ThumbnailComponent
        attr_reader :document
        delegate :id, :thumbnail_url, to: :document

        def thumbnail_image
          content_tag :div, class: 'document-thumbnail', data: { controller: 'image-zoom' } do
            concat image_tag(thumbnail_url, alt: 'thumbnail', class: 'img-thumbnail', loading: 'lazy', data: {
              action: 'click->image-zoom#open',
              image_zoom_target: 'trigger',
              zoomed_image_url: document.image_url
            })
            concat render(Arcdex::ZoomedCardViewComponent.new(document:))
          end
        end
      end
    end
  end
end
