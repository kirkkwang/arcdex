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

    def viewer
      content_tag :iframe, nil,
                  src: "/mirador_viewer.html?manifest=#{manifest_solr_document_url(id: document.id)}&theme=#{theme}",
                  width: '100%',
                  height: '700px',
                  allow: 'fullscreen'
    end

    def theme
      helpers.cookies[:theme] || 'dark'
    end
  end
end
