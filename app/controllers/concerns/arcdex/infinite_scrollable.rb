module Arcdex
  module InfiniteScrollable
    extend ActiveSupport::Concern

    included do
      alias_method :infinite_scroll_index, :index
    end

    def index
      @response = search_service.search_results

      respond_to do |format|
        format.html { store_preferred_view }
        format.rss  { render layout: false }
        format.atom { render layout: false }
        format.json do
          if params[:infinite_scroll]
            # For infinite scroll, render the documents using the HTML partial
            render json: {
              documents_html: render_to_string(
                partial: 'document_list',
                formats: [:html],  # Force HTML format
                locals: {
                  documents: @response.documents,
                  view_config: blacklight_config.view_config(params[:view] || 'gallery')
                }
              ),
              pagination: {
                current_page: @response.current_page,
                total_pages: @response.total_pages,
                next_page: @response.next_page,
                has_next_page: @response.next_page.present?
              }
            }
          else
            # Standard JSON response
            @presenter = Blacklight::JsonPresenter.new(@response, blacklight_config)
          end
        end
        additional_response_formats(format)
        document_export_formats(format)
      end
    end
  end
end
