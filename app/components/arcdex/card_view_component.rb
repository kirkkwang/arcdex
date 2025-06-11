module Arcdex
  class CardViewComponent < Arcdex::UpperMetadataLayoutComponent
    def image
      content_tag :img, nil,
                  src: document.image_url,
                  alt: 'Card image',
                  class: 'large-card-image',
                  data: {
                    action: 'click->image-zoom#open',
                    image_zoom_target: 'trigger',
                    zoomed_image_url: document.image_url
                  }
    end
  end
end
