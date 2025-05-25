# frozen_string_literal: true

# Represents a single document returned from Solr
class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument
  include Arclight::SolrDocument

  # self.unique_key = 'id'

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  def series
    self['series_ssm']&.first || ''
  end

  def master_set?
    self['printed_total_isi'] < self['total_items_isi']
  end

  def master_set_count
    self['total_items_isi'] || ''
  end

  def complete_set_count
    self['printed_total_isi'] || ''
  end

  def logo_url
    self['logo_url_ssm'].first || ''
  end

  def release_date
    self['release_date_ssm'].first || ''
  end

  def icon_url
    collection? ? self['symbol_url_ssm'].first : self['small_url_ssm'].first
  end

  def supertype
    self['supertype_ssm'].first || ''
  end

  # OVERRIDE Arclight v2.0.0.alpha to look for series_ssm instead of repository_ssm
  def repository
    first('series_ssm') || collection&.first('series_ssm')
  end

  # OVERRIDE Arclight v2.0.0.alpha to use find instead of find_by
  def repository_config
    return unless repository

    @repository_config ||= Arclight::Repository.find(repository)
  end

  def flavor_text_html
    self['flavor_text_html_ssm']&.first || ''
  end

  def image_html
    (collection? ? self['logo_url_html_ssm'].first : self['large_url_html_ssm']&.first) || ''
  end

  # OVERRIDE Arclight v2.0.0.alpha to get set id
  def collection_unitid
    collection&.id
  end

  def tcg_player_price_updated_at
    self['tcg_player_price_updated_at_ssi'] || ''
  end

  def tcg_player_prices_object
    begin
      JSON.parse(self['tcg_player_prices_json_ssi'])
    rescue JSON::ParserError, TypeError
      {}
    end
  end
end
