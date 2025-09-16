# OVERRIDE Blacklight v8.11.0 to add 4 columns of cards to bookmark index view
#   and infinite scroll support
#   and to do some custom blacklight configurations

module BookmarksControllerDecorator
  def index
    @bookmarks = token_or_current_or_guest_user.bookmarks
    @classes = 'row-cols-2 row-cols-md-3 row-cols-lg-4'

    configure_blacklight_config!

    infinite_scroll_index do
      return if params[:sort].present?

      sort_order = token_or_current_or_guest_user.bookmark_order || @bookmarks.pluck(:document_id)
      @response.documents.sort_by! do |doc|
        sort_order.index(doc.id) || Float::INFINITY
      end
    end
  end

  def update_order
    order_array = params[:new_order].split(',')

    if token_or_current_or_guest_user.update_bookmark_order!(order_array)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def configure_blacklight_config!
    blacklight_config.index.classes = @classes if search_service.search_results.documents.count > 3
    blacklight_config.per_page = [@bookmarks.count]
    blacklight_config.sort_fields.clear
    blacklight_config.add_sort_field ' ', label: 'custom order' # using space to make the sort blank
    blacklight_config.add_sort_field 'release_date_sort desc, sort_ssi asc', label: 'release date (new to old)'
    blacklight_config.add_sort_field 'release_date_sort asc, sort_ssi asc', label: 'release date (old to new)'
  end
end

BookmarksController.prepend(BookmarksControllerDecorator)
