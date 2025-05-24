# OVERRIDE Arclight v2.0.0.alpha to not show the collection sidebar sections and show a custom
#   collection context component

module Arclight
  module SidebarComponentDecorator
    def collection_context
      render Arcdex::CollectionContextComponent.new(presenter: document_presenter(document), download_component: Arclight::DocumentDownloadComponent)
    end

    def collection_sidebar; end
  end
end

Arclight::SidebarComponent.prepend(Arclight::SidebarComponentDecorator)
