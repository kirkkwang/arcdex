# OVERRIDE Blacklight v8.11.0 to not render the search navbar
#   when we're on the advanced search page
module Blacklight
  module SearchNavbarComponentDecorator
    def render?
      return false if action_name == 'advanced_search'

      super
    end
  end
end

Blacklight::SearchNavbarComponent.prepend(Blacklight::SearchNavbarComponentDecorator)
