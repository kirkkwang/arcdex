module Arcdex
  class PokemonSearchComponent < Arcdex::UpperMetadataLayoutComponent
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
            search_field: 'card_name')
        )
      end

      values.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ').html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
