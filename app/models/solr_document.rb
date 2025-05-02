# frozen_string_literal: true

# Represents a single document returned from Solr
class SolrDocument
  include Blacklight::Solr::Document
  include Arclight::SolrDocument

  # self.unique_key = 'id'

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  def series
    self["series_ssm"]&.first || ""
  end

  def master_set?
    self["printed_total_isi"] < self["total_items_isi"]
  end

  def logo_url
    self["logo_url_ssm"].first || ""
  end

  def release_date
    self["release_date_ssm"].first || ""
  end
end
