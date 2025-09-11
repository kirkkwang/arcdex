module Arcdex
  class CardListComponent < ViewComponent::Base
    attr_reader :document, :card_list

    def initialize(document:)
      @document = document
      @card_list = document.cards
    end

    private

    def card_list_items
      card_list.map do |card|
        content_tag :li,
                    id: "#{card.id}-card-list-item",
                    class: classes_for(card) do
          card_item_content(card)
        end
      end.join.html_safe # rubocop:disable Rails/OutputSafety
    end

    def card_item_content(card)
      content_tag :div, class: 'documentHeader', data: { document_id: card.id } do
        content_tag :div, class: 'index_title document-title-heading' do
          current_card?(card) ? card.title : link_to(card.title, "#{card.id}#title")
        end
      end
    end

    def classes_for(card)
      classes = 'blacklight-card document al-collection-context'
      classes << ' al-hierarchy-highlight' if current_card?(card)
      classes
    end

    def current_card?(card)
      params[:id] == card.id
    end
  end
end
