# frozen_string_literal: true

# OVERRIDE Blacklight v8.12.2 to pass view=gallery param from advanced search form

module Arcdex
  class AdvancedSearchFormComponent < ::Blacklight::AdvancedSearchFormComponent
    def hidden_search_state_params
      super.except(:f).merge({ view: 'gallery' })
    end

    def default_operator_menu
      options_with_labels = [:must, :should].index_by { |op| t(op, scope: 'blacklight.advanced_search.op') }
      label_tag(:op, t('blacklight.advanced_search.op.label'), class: 'visually-hidden') + select_tag(:op, options_for_select(options_with_labels, params[:op]), class: 'form-select flex-shrink-0', style: 'width: 142px;', id: nil)
    end

    def initial_clause_field
      @params.dig(:clause, '0', 'field').presence || @search_field.presence || search_fields.keys.first
    end

    def initial_clause_query
      @params.dig(:clause, '0', 'query').presence || @q
    end
  end
end
