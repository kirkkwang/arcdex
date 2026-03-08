# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchBuilder do
  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:scope) { double('scope', blacklight_config:, action_name: 'index') } # rubocop:disable RSpec/VerifiedDoubles

  def build(params = {})
    described_class.new(scope).with(params)
  end

  describe '#exclude_facets' do
    it 'does nothing when there are no negated facet keys' do
      solr_params = {}
      build(f: { 'rarity' => ['Rare'] }).exclude_facets(solr_params)
      expect(solr_params[:fq]).to be_nil
    end

    it 'does nothing when f is absent' do
      solr_params = {}
      build.exclude_facets(solr_params)
      expect(solr_params[:fq]).to be_nil
    end

    it 'builds a NOT fq clause for a negated facet key' do
      solr_params = {}
      build(f: { '-rarity' => ['Rare'] }).exclude_facets(solr_params)
      expect(solr_params[:fq]).to include('-rarity_ssm:("Rare")')
    end

    it 'combines existing fq with the negated clause' do
      solr_params = { fq: ['level_ssm:collection'] }
      build(f: { '-rarity' => ['Rare'] }).exclude_facets(solr_params)
      expect(solr_params[:fq]).to include('-rarity_ssm:("Rare")')
      expect(solr_params[:fq]).to include('(_query_:"level_ssm:collection")')
    end

    it 'handles multiple negated values with OR' do
      solr_params = {}
      build(f: { '-rarity' => ['Rare', 'Common'] }).exclude_facets(solr_params)
      expect(solr_params[:fq]).to include('"Rare" OR "Common"')
    end

    it 'uses handle_query and removes the key when the facet has a query config' do
      config = CatalogController.blacklight_config.deep_copy
      config.add_facet_field 'hp', field: 'hp_ssm', query: {
        low: { label: 'Low', fq: 'hp_ssm:[0 TO 50]' }
      }
      custom_scope = double('scope', blacklight_config: config, action_name: 'index') # rubocop:disable RSpec/VerifiedDoubles
      solr_params = {}
      described_class.new(custom_scope).with(f: { '-hp' => ['low'] }).exclude_facets(solr_params)
      expect(solr_params[:fq]).to include('-hp_ssm:[0 TO 50]')
    end
  end

  describe '#filter_sets_on_grouped_search' do
    it 'adds a -level_ssm:collection fq when grouping' do
      solr_params = { group: true }
      build.filter_sets_on_grouped_search(solr_params)
      expect(solr_params[:fq]).to include('-level_ssm:collection')
    end

    it 'does nothing when not grouping' do
      solr_params = {}
      build.filter_sets_on_grouped_search(solr_params)
      expect(solr_params[:fq]).to be_nil
    end
  end

  describe '#sort_by_string' do
    it 'replaces sort_isi with sort_ssi in the sort parameter' do
      solr_params = { sort: 'sort_isi asc' }
      build.sort_by_string(solr_params)
      expect(solr_params[:sort]).to eq('sort_ssi asc')
    end

    it 'does nothing when sort is nil' do
      solr_params = {}
      build.sort_by_string(solr_params)
      expect(solr_params[:sort]).to be_nil
    end
  end

  describe '#facet_limit_with_pagination' do
    it 'returns nil on the advanced_search action' do
      advanced_scope = double('scope', blacklight_config:, action_name: 'advanced_search') # rubocop:disable RSpec/VerifiedDoubles
      result = described_class.new(advanced_scope).with({}).facet_limit_with_pagination('rarity')
      expect(result).to be_nil
    end

    it 'delegates to super on other actions' do
      # super returns nil when there is no per-page limit configured for the field
      result = build.facet_limit_with_pagination('rarity')
      expect(result).not_to be_nil
    end
  end
end
