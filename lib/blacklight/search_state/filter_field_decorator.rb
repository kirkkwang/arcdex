# OVERRIDE Blacklight v8.9.0 to support exclude facets by adding the NOT operator to the url_key

module Blacklight
  module SearchState::FilterFieldDecorator
    def remove(item, exclude: false)
      new_state = search_state.reset_search

      return new_state.filter(item.field).remove(item) if item.respond_to?(:field) && item.field != key

      url_key = config.key
      params = new_state.params

      param = filters_key
      value = as_url_parameter(item)

      if value == Blacklight::SearchState::FilterField::MISSING
        url_key = "-#{key}"
        value = Blacklight::Engine.config.blacklight.facet_missing_param
      elsif exclude
        url_key = "-#{key}"
      end

      param = inclusive_filters_key if value.is_a?(Array)

      # need to dup the facet values too,
      # if the values aren't dup'd, then the values
      # from the session will get remove in the show view...
      params[param] = (params[param] || {}).dup
      params[param][url_key] = (params[param][url_key] || []).dup

      collection = params[param][url_key]

      params[param][url_key] = collection - Array(value)
      params[param].delete(url_key) if params[param][url_key].empty?
      params.delete(param) if params[param].empty?

      new_state.reset(params)
    end
  end
end

Blacklight::SearchState::FilterField.prepend(Blacklight::SearchState::FilterFieldDecorator)
