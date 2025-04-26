# OVERRIDE Arclight v2.0.0.aplpha to return the series name and facet link instead of Repository

module Arclight
  module BreadcrumbsHierarchyComponentDecorator
    def repository
      series = document.series

      link_to(series, helpers.search_catalog_path(f: { series: [ series ] }, search_field: "all_fields"))
    end
  end
end

Arclight::BreadcrumbsHierarchyComponent.prepend(Arclight::BreadcrumbsHierarchyComponentDecorator)
