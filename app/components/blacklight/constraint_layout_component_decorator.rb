module Blacklight
  module ConstraintLayoutComponentDecorator
    def remove_aria_label
      return super unless @classes.include?(helpers.blacklight_config.view_config.constraints_component_exclude_styling)

      if @label.blank?
        t('blacklight.search.filters.remove_excluded.value', value: @value)
      else
        t('blacklight.search.filters.remove_excluded.label_value', label: @label, value: @value)
      end
    end
  end
end

Blacklight::ConstraintLayoutComponent.prepend(Blacklight::ConstraintLayoutComponentDecorator)
