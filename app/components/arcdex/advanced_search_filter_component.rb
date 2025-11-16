module Arcdex
  class AdvancedSearchFilterComponent < ::Blacklight::FacetFieldCheckboxesComponent
    def facet_field_id
      "advanced_search_#{@facet_field.key}"
    end

    def facet_field_label
      t("blacklight.advanced_search.form.filter.#{@facet_field.key}", default: @facet_field.label)
    end

    def facet_options
      @facet_field.display_facet.items.map do |item|
        tag.option(value: item.value) do
          item.label
        end
      end.join.html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
