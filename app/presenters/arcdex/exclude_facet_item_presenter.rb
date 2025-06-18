# Supports exclude facets to make sure the remove constraint link properly removes
#   the constraint and also adding a css class so we can apply specific styling
module Arcdex
  class ExcludeFacetItemPresenter < ::Blacklight::FacetItemPresenter
    def classes
      view_context.blacklight_config.view_config.constraints_component_exclude_styling
    end
  end
end
