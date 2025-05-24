# OVERRIDE Arcdex v2.0.0.alpha to show custom html and no download button

module Arcdex
  class CollectionContextComponent < ::Arclight::CollectionContextComponent
    def collection_info
      render Arcdex::CollectionInfoComponent.new(collection:)
    end
  end
end
