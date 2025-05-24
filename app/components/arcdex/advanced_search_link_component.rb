module Arcdex
  class AdvancedSearchLinkComponent < ::Blacklight::Component
    def initialize(text:, id:, url: '/catalog/advanced')
      @text = text
      @id = id
      @url = url
    end

    def call
      tag.a(href: @url, class: 'advanced_search btn btn-secondary text-nowrap') do
        tag.span(t('blacklight.advanced_search.more_options'),
                class: 'visually-hidden-sm me-sm-1 submit-search-text') +
          render(Arcdex::Icons::AdvancedSearchComponent.new)
      end
    end
  end
end
