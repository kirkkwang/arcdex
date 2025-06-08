# OVERRIDE Arclight v1.5.0 to not show the collection sidebar sections and show a custom
#   collection context component.  Also we don't need the turbo tags since the card list is
#   usually pretty small not nested.

module Arcdex
  module Arclight
    class SidebarComponent < ::Arclight::SidebarComponent
      def collection_context
        render Arcdex::CollectionContextComponent.new(presenter: document_presenter(document), download_component: ::Arclight::DocumentDownloadComponent)
      end

      def collection_sidebar; end
    end
  end
end
