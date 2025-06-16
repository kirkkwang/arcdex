# OVERRIDE Blacklight v8.11.0 to pass view=gallery param from advanced search form

module Blacklight
  module AdvancedSearchFormComponentDecorator
    def hidden_search_state_params
      super.merge({ view: 'gallery' })
    end
  end
end

Blacklight::AdvancedSearchFormComponent.prepend(Blacklight::AdvancedSearchFormComponentDecorator)
