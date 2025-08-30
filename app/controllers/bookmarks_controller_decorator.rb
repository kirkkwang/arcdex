# OVERRIDE Blacklight v8.11.0 to add 4 columns of cards to bookmark index view

module BookmarksControllerDecorator
  def index
    @bookmarks = token_or_current_or_guest_user.bookmarks
    classes = 'row-cols-2 row-cols-md-3 row-cols-lg-4'
    blacklight_config.index.classes = classes if search_service.search_results.documents.count > 3

    infinite_scroll_index
  end
end

BookmarksController.prepend(BookmarksControllerDecorator)
