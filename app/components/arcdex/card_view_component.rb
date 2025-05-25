module Arcdex
  class CardViewComponent < Arcdex::UpperMetadataLayoutComponent
    def image
      document.image_html.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
