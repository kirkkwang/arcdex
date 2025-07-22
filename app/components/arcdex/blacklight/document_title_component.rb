# OVERRIDE Blacklight v8.9.0 to not render post call in title link so the
#   back button from the show page doesn't make a server call and messing
#   up infinite scroll positioning on the index page

module Arcdex
  module Blacklight
    class DocumentTitleComponent < ::Blacklight::DocumentTitleComponent
      def title
        link_to(@document.title, solr_document_path(@document), itemprop: 'name')
      end
    end
  end
end
