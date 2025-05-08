# OVERRIDE Blacklight Gallery v4.8.4 to add lazy loading to thumbnails

module Blacklight
  module Gallery
    module DocumentComponentDecorator
      def before_render
        with_thumbnail(image_options: { class: "img-thumbnail", loading: "lazy" }) unless thumbnail.present?
        super
      end
    end
  end
end

Blacklight::Gallery::DocumentComponent.prepend(Blacklight::Gallery::DocumentComponentDecorator)
