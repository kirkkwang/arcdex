# OVERRIDE Arclight v2.0.0.alpha to not show the collection context and collection sidebar sections

module Arclight
  module SidebarComponentDecorator
    def collection_context; end

    def collection_sidebar; end
  end
end

Arclight::SidebarComponent.prepend(Arclight::SidebarComponentDecorator)
