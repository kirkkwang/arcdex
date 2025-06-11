module Arcdex
  class CardViewComponent < Arcdex::UpperMetadataLayoutComponent
    attr_reader :url

    def initialize(document: nil, url: nil, **kwargs)
      @document = document || kwargs[:field]&.document
      @url = url || @document&.image_url
    end

    def image
      content_tag :img, nil,
                  src: url,
                  alt: 'Card image',
                  class: 'large-card-image',
                  data: {
                    action: 'click->image-zoom#open',
                    image_zoom_target: 'trigger',
                    zoomed_image_url: document&.image_url
                  }
    end
  end
end
