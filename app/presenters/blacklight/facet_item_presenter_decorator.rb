# OVERRIDE Blacklight v9.2.1 to support exclude facets by adding the exclude href to
#   the link/icon of the terms.

module Blacklight
  module FacetItemPresenterDecorator
    def exclude_href(path_options = {})
      add_exclude_href(path_options)
    end

    def selected?
      search_state.filter(facet_config).include?(value) || search_state.params[:f]&.[]("-#{key}")&.include?(value)
    end

    def remove_href(path = search_state)
      return super unless excluded_facet_item?

      excluded_key = "-#{facet_config.key}"
      view_context.search_action_path(path.filter(excluded_key).remove(facet_item))
    end

    def excluded_facet_item?
      search_state.params.dig(:f, "-#{facet_config.key}")&.include?(value.to_s)
    end

    private

    def add_exclude_href(path_options = {})
      negated_facet_config_key = '-' + facet_config.key
      view_context.search_action_path(search_state.add_facet_params_and_redirect(negated_facet_config_key, facet_item).merge(path_options))
    end
  end
end

Blacklight::FacetItemPresenter.prepend(Blacklight::FacetItemPresenterDecorator)
