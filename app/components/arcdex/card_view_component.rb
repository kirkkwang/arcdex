module Arcdex
  class CardViewComponent < Arcdex::UpperMetadataLayoutComponent
    delegate :id, :image_url, :flavor_text_html, to: :document

    def image
      content_tag :img, nil,
                  src: image_url,
                  alt: 'Card image',
                  class: 'large-card-image',
                  data: {
                    action: 'click->image-zoom#open',
                    image_zoom_target: 'trigger',
                    zoomed_image_url: image_url
                  }
    end

    def viewer
      render Arcdex::MiradorViewerComponent.new(id:)
    end

    def flavor_text
      flavor_text_html.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
