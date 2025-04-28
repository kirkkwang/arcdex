# OVERRIDE Arclight v2.0.0.alpha helper methods

module ArclightHelperDecorator
  def show_content_classes
    "col-12 col-lg-9 show-document order-2"
  end

  def show_sidebar_classes
    "col-lg-3 order-1 collection-sidebar"
  end
end

ArclightHelper.prepend(ArclightHelperDecorator)
