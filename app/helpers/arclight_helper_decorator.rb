# OVERRIDE Arclight v2.0.0.alpha helper methods

module ArclightHelperDecorator
  def show_content_classes
    "col-12 col-lg-9 show-document order-2"
  end

  def show_sidebar_classes
    "col-lg-3 order-1 collection-sidebar"
  end

  def sets_path
    search_action_url(
      f: {
        Category: [ "Set" ]
      }
    )
  end

  def repository_collections_path(repository)
    search_action_url(
      f: {
        series: [ repository.name ],
        Category: [ "Set" ]
      }
    )
  end

  def repository_path(name)
    "/repositories/#{name}"
  end
end

ArclightHelper.prepend(ArclightHelperDecorator)
