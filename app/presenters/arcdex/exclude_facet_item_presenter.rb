# Supports exclude facets to make sure the remove constraint link properly removes
#   the constraint and also adding a css class so we can apply specific styling
module Arcdex
  class ExcludeFacetItemPresenter < Blacklight::FacetItemPresenter
    def remove_href(path = search_state)
      view_context.search_action_path(path.filter(facet_config.key).remove(facet_item, exclude: true))
    end

    def classes
      'exclude-filter'
    end
  end
end
