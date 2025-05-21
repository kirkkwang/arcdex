# OVERRIDE Blacklight v8.9.0 to support exclude facets to allow constraints to render

module Blacklight
  module SearchStateDecorator
    def has_constraints?
      !(query_param.blank? && filters.blank? && clause_params.blank? && exclude_facets.blank?)
    end

    private

    def exclude_facets
      keys = params[:f]&.keys
      return [] if keys.nil?

      keys.select { |key| key.starts_with?('-') }
    end
  end
end

Blacklight::SearchState.prepend(Blacklight::SearchStateDecorator)
