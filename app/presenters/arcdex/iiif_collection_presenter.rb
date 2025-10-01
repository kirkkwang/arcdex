module Arcdex
  class IiifCollectionPresenter
    attr_reader :base_url, :series

    def initialize(series:, base_url:)
      @series = series
      @base_url = base_url
    end

    def as_json
      {}.tap do |collection|
        collection['@context'] = 'http://iiif.io/api/presentation/3/context.json'
        collection[:id] = generate_id
        collection[:type] = 'Collection'
        collection[:label] = { en: [series.name] }
        collection[:items] = items
        collection[:rights] = 'http://rightsstatements.org/vocab/InC/1.0/'
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
          thumbnail: [thumbnail(set)]
        }
      end
    end

    def thumbnail(set)
      {
        id: set.thumbnail_url,
        type: 'Image',
        height: 342,
        width: 245,
        format: 'image/png'
      }
    end

    def required_statement
      {
        label: { en: ['Attribution'] },
        value: { en: ['Data provided by <a href="https://pokemontcg.io/" target="_blank">Pokémon TCG Developers</a>'] }
      }
    end

    def catalog_id(base_url, set)
      "#{base_url.gsub('/series', '/catalog')}/#{set.id}/manifest"
    end
  end
end
