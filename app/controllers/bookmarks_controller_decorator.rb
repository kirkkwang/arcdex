# OVERRIDE Blacklight v8.11.0 to add 4 columns of cards to bookmark index view

module BookmarksControllerDecorator
  def index
    @bookmarks = token_or_current_or_guest_user.bookmarks
    @response = search_service.search_results

    # OVERRIDE begin
    classes = 'row-cols-2 row-cols-md-3 row-cols-lg-4'
    blacklight_config.index.classes = classes if search_service.search_results.documents.count > 3
    # OVERRIDE end

    respond_to do |format|
      format.html
      format.rss  { render layout: false }
      format.atom { render layout: false }

      additional_response_formats(format)
      document_export_formats(format)
    end
  end
end

BookmarksController.prepend(BookmarksControllerDecorator)
