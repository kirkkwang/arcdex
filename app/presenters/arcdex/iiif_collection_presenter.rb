module Arcdex
  class IiifCollectionPresenter
    include Arcdex::IiifPresentable

    attr_reader :base_url, :series

    def initialize(series:, base_url:)
      @series = series
      @base_url = base_url
    end

    def as_json
      {}.tap do |collection|
        collection['@context'] = presentation_api_url
        collection[:id] = generate_id
        collection[:type] = 'Collection'
        collection[:label] = { en: [series.name] }
        collection[:items] = items
        collection[:rights] = rights_statement
        collection[:requiredStatement] = required_statement
      end
    end

    private

    def generate_id
      "#{base_url}/#{series.name}/manifest"
    end

    def items
      series.documents.map do |set|
        {
          id: catalog_id(base_url, set),
          type: 'Manifest',
          label: { en: [set.title] },
          thumbnail: [thumbnail_body(set.thumbnail_url)]
        }
      end
    end

    def catalog_id(base_url, set)
      "#{base_url.gsub('/series', '/catalog')}/#{set.id}/manifest"
    end
  end
end
