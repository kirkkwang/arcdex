# OVERRIDE Arclight v2.0.0.alpha to remove BookmarkComponent from rendering

module Arcdex
  module Arclight
    class DocumentComponent < ::Arclight::DocumentComponent; end
  end
end
