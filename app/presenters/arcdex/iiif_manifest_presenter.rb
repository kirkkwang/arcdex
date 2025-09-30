module Arcdex
  class IiifManifestPresenter
    attr_reader :documents, :start_id, :set_id, :fields, :base_url, :from_bookmarks

    PRESENTATION_API_URL = 'http://iiif.io/api/presentation/3/context.json'
    RIGHTS_STATEMENT = 'http://rightsstatements.org/vocab/InC/1.0/'

    def initialize(base_url:, start_id:, fields:, documents:, set_id:, from_bookmarks: false)
      @base_url = base_url
      @start_id = start_id
      @fields = fields
      @documents = documents
      @set_id = set_id
      @from_bookmarks = from_bookmarks
    end

    def as_json
      {}.tap do |manifest|
        manifest['@context'] = PRESENTATION_API_URL
        manifest[:id] = "#{generate_id}/manifest"
        manifest[:start] = start unless start_id == set_id
        manifest[:type] = 'Manifest'
        manifest[:label] = label
        manifest[:items] = Arcdex::IiifCanvasesPresenter.new(documents:, base_url:, fields:).as_json
        manifest[:rights] = RIGHTS_STATEMENT
        manifest[:requiredStatement] = required_statement
        manifest[:homepage] = [homepage] unless from_bookmarks
        manifest[:thumbnail] = [{
          id: SolrDocument.find(set_id).thumbnail_url,
          type: 'Image',
          height: 342,
          width: 245,
          format: 'image/png'
        }]
      end
    end

    private

    def start
      {
        id: "#{generate_id(id: start_id)}/canvas",
        type: 'Canvas'
      }
    end

    def label
      {
        en: [manifest_label]
      }
    end

    def required_statement
      {
        label: { en: ['Attribution'] },
        value: { en: ['Data provided by <a href="https://pokemontcg.io/" target="_blank">Pokémon TCG Developers</a>'] }
      }
    end

    def homepage
      {
        id: generate_id(id: set_id),
        type: 'Text',
        label: { en: ['View Set'] },
        format: 'text/html'
      }
    end

    def generate_id(id: nil)
      id = id || set_id
      base_url + (id ? "/#{id}" : '')
    end

    def manifest_label
      return 'Custom Set' if from_bookmarks

      series = Array.wrap(documents.first['series_ssm'])
      set = Array.wrap(documents.first['parent_unittitles_ssm'])
      "#{series.first} - #{set.first}"
    end
  end
end
