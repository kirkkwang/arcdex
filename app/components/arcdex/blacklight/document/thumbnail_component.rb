# OVERRIDE Blacklight v8.11.0 to render custom thumbnail with zoomable image

module Arcdex
  module Blacklight
    module Document
      class ThumbnailComponent < ::Blacklight::Document::ThumbnailComponent; end
    end
  end
end
