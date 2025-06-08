# OVERRIDE Arclight v2.0.0.alpha because we call our "collections" "sets"
#   and to make gallery view the default view.

module Arcdex
  module Arclight
    class SearchBarComponent < ::Arclight::SearchBarComponent
      def initialize(url:, **args)
        params = args[:params] || {}
        view_param = params[:view].presence || 'gallery'
        super(url:, **args, params: params.merge({ view: view_param }))
      end
    end
  end
end
