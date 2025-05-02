# OVERRIDE Arclight v2.0.0.alpha to go to the series (repository).

module Arclight
  module BreadcrumbsHierarchyComponentDecorator
    def repository
      series = document.series

      link_to(series, helpers.repository_path(series))
    end
  end
end

Arclight::BreadcrumbsHierarchyComponent.prepend(Arclight::BreadcrumbsHierarchyComponentDecorator)
