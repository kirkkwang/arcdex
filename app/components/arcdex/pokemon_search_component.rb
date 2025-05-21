module Arcdex
  class PokemonSearchComponent < ::Arclight::UpperMetadataLayoutComponent
    attr_reader :field, :document

    def initialize(field:, label_class: 'col-md-3 offset-md-1', value_class: 'col-md-8', **)
      super(field:, label_class:, value_class:)

      @document = field.document
    end

    def label
      "#{field.field_config.label}:"
    end

    def pokemon_search(field, values)
      method =
        if field.include?('evolves_from')
          :evolves_from
        elsif field.include?('evolves_to')
          :evolves_to
        end

      values.map! do |value|
        link_to(
          value,
          helpers.search_action_url(
            f: { supertype: [document.supertype] },
            q: value,
            search_field: 'normalized_title_ssm')
        )
      end

      values.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ').html_safe
    end
  end
end
