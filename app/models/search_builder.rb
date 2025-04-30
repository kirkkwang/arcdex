# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  include Arclight::SearchBehavior

  self.default_processor_chain += [ :exclude_facets ]

  ##
  # @example Adding a new step to the processor chain
  #   self.default_processor_chain += [:add_custom_data_to_query]
  #
  #   def add_custom_data_to_query(solr_parameters)
  #     solr_parameters[:custom] = blacklight_params[:user_value]
  #   end

  # Adding logic to alter the fq to exclude facets using the '-' (NOT) operator
  def exclude_facets(solr_parameters)
    f = blacklight_params[:f]&.select { |key, _| key.starts_with?("-") }
    return if f.blank?

    queries = []
    f.each_key do |key|
      query = blacklight_config.facet_fields[key[1..]]&.query
      if query.present?
        queries << handle_query(query)
        f.delete(key)
      end
    end

    queries << f.map { |key, value| "#{solr_field_for(key)}:(#{value.map { |v| "\"#{v}\"" }.join(' OR ')})" }.join(" AND ")
    queries.compact_blank!

    solr_parameters[:fq] = if queries.present? && solr_parameters[:fq].present?
                             (solr_parameters[:fq].map { |fq| "(_query_:\"#{fq}\")" } + queries).join(" AND ")
    elsif queries.present? && solr_parameters[:fq].blank?
                             queries.join(" AND ")
    end
  end

  private

  def solr_field_for(key)
    key = key[1..] # remove the leading '-'

    field = blacklight_config.facet_fields[key]&.field
    return if field.nil?

    "-" + field
  end

  def handle_query(query)
    query.values.map { |entry| "-" + entry[:fq] }.join(" AND ")
  end
end
