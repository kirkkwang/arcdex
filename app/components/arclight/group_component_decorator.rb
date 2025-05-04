# OVERRIDE Arclight v2.0.0.alpha to make the view all {count} link work with "set" instead of "collection"

module Arclight
  module GroupComponentDecorator
    def search_within_collection_url
      search_catalog_path(helpers.search_without_group.deep_merge(f: { set: [ document.collection_name ] }))
    end
  end
end

Arclight::GroupComponent.prepend(Arclight::GroupComponentDecorator)
