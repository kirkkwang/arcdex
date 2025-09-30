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
        collection[:items] = series.documents.map do |set|
          {
            id: "#{base_url.gsub('/series', '/catalog')}/#{set.id}/manifest",
            type: 'Manifest',
            label: { en: ["#{set.title}"] }
          }
        end
        collection[:rights] = 'http://rightsstatements.org/vocab/InC/1.0/'
        collection[:requiredStatement] = {
          label: { en: ['Attribution'] },
          value: { en: ['Data provided by <a href="https://pokemontcg.io/" target="_blank">Pokémon TCG Developers</a>'] }
        }
      end
    end

    def generate_id
      "#{base_url}/#{series.name}/manifest"
    end
  end
end
