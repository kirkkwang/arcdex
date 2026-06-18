module Arcdex
  class AdvancedSearchFilterComponent < ::Blacklight::FacetFieldCheckboxesComponent
    MISSING_PARAM = ::Blacklight::Engine.config.blacklight.facet_missing_param

    def facet_field_id
      "advanced_search_#{@facet_field.key}"
    end

    def facet_field_label
      t("blacklight.advanced_search.form.filter.#{@facet_field.key}", default: @facet_field.label)
    end

    def facet_options
      options = @facet_field.display_facet.items.map do |item|
        option_tag(item.value, item.label)
      end

      extra = selected_values - @facet_field.display_facet.items.map(&:value)
      options += extra.map { |value| option_tag(value, value) }

      options.join.html_safe # rubocop:disable Rails/OutputSafety
    end

    def excludable?
      @facet_field.facet_field.excludable
    end

    def excluded?
      excludable? && inclusive_values.empty? && excluded_values.any?
    end

    def selected_values
      excluded? ? excluded_values : inclusive_values
    end

    def filter_field_name
      excluded? ? "f[-#{@facet_field.key}][]" : "f_inclusive[#{@facet_field.key}][]"
    end

    private

    def option_tag(value, label)
      tag.option(value: value, selected: selected_values.include?(value)) do
        label
      end
    end

    def inclusive_values
      @inclusive_values ||= @facet_field.search_state
                                        .filter(@facet_field.facet_field)
                                        .values(except: [:missing])
                                        .flatten.compact
    end

    def excluded_values
      @excluded_values ||= Array(@facet_field.search_state.params.dig(:f, "-#{@facet_field.key}"))
                           .reject { |value| value == MISSING_PARAM }
    end
  end
end
