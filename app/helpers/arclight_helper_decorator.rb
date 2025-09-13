# OVERRIDE Arclight v2.0.0.alpha helper methods

module ArclightHelperDecorator
  def show_content_classes
    'col-12 col-lg-9 show-document order-2'
  end

  def show_sidebar_classes
    'col-lg-3 order-1 collection-sidebar'
  end

  def sets_path
    search_path_with_view(f: { Category: ['Set'] })
  end

  def cards_path
    search_path_with_view(f: { Category: ['Card'] })
  end

  def search_path_with_view(base_params)
    search_params = base_params.dup
    search_params[:view] = params[:view] || 'gallery'
    search_action_url(search_params)
  end

  def repository_collections_path(repository)
    search_action_url(
      f: {
        series: [repository.name],
        Category: ['Set']
      }
    )
  end

  def repository_path(name)
    "/repositories/#{name}"
  end

  def sanitized_nest_path
    params[:nest_path]&.include?('/components#') ? params[:nest_path] : nil
  end

  def collection_active?
    search_state.filter('Category').values == ['Set']
  end

  def collection_active_class
    'active' if collection_active?
  end

  def card_active?
    search_state.filter('Category').values == ['Card']
  end

  def card_active_class
    'active' if card_active?
  end

  def last_navbar_partial?(config)
    config == blacklight_config.navbar.partials.values.last
  end

  def bookmarks_to_catalog_search_path(bookmarks)
    search_catalog_url(
      search_field: 'id',
      q: bookmarks.pluck(:document_id).join(' OR '),
      view: 'gallery'
    )
  end

  def mirador_viewer(id:, encode: false, maximized: true)
    encoded_id = Arcdex::Hashids.encode(id) if encode

    encoded_id ||= id

    "/mirador_viewer.html?manifest=#{manifest_solr_document_url(encoded_id)}&theme=#{preferred_theme}&maximized=#{maximized}"
  end

  def preferred_theme
    cookies[:theme] || 'dark'
  end
end

ArclightHelper.prepend(ArclightHelperDecorator)
