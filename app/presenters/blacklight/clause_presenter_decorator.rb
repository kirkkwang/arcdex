module Blacklight
  module ClausePresenterDecorator
    def classes; end
  end
end

Blacklight::ClausePresenter.prepend(Blacklight::ClausePresenterDecorator)
