module Arcdex
  class CardViewComponent < Arcdex::UpperMetadataLayoutComponent
    delegate :id, :image_url, to: :document

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
  end
end
