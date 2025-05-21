# OVERRIDE Blacklight v8.9.0 to support exclude facets by adding a link/icon for users
#   to click on the exclude certains results

module Blacklight
  module FacetItemComponentDecorator
    attr_reader :exclude_href

    def initialize(facet_item:, wrapping_element: 'li', suppress_link: false)
      super

      @exclude_href = facet_item.exclude_href
    end

    def render_facet_value
      exclude_facet_link + super
    end

    def exclude_facet_link
      link_to_unless(@suppress_link, exclude_filter_icon, exclude_href, class: 'me-1 exclude-facet-link', rel: 'nofollow')
    end

    private

    def exclude_filter_icon
      return '' unless @facet_item.facet_config.excludable

      tag.span('Ⓧ', class: 'exclude-facet-icon', title: 'Exclude facet', label: @label)
    end
  end
end

Blacklight::FacetItemComponent.prepend(Blacklight::FacetItemComponentDecorator)
