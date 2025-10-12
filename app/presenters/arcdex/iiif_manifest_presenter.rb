module Arcdex
  class IiifManifestPresenter
    include Arcdex::IiifPresentable

    attr_reader :documents, :start_id, :set_id, :fields, :base_url, :series, :from_bookmarks

    def initialize(base_url:, start_id:, fields:, documents:, set_id:, from_bookmarks: false)
      @base_url = base_url
      @start_id = start_id
      @fields = fields
      @documents = documents
      @set_id = set_id
      @series = SolrDocument.find(set_id).series unless from_bookmarks
      @from_bookmarks = from_bookmarks
    end

    def as_json
      {}.tap do |manifest|
        manifest['@context'] = presentation_api_url
        manifest[:id] = "#{generate_id}/manifest"
        manifest[:start] = start unless start_id == set_id
        manifest[:type] = 'Manifest'
        manifest[:label] = label
        manifest[:items] = Arcdex::IiifCanvasesPresenter.new(documents:, base_url:, fields:).as_json
        manifest[:rights] = rights_statement
        manifest[:requiredStatement] = required_statement
        manifest[:homepage] = [homepage] unless from_bookmarks
        manifest[:thumbnail] = [thumbnail_body(SolrDocument.find(set_id).thumbnail_url)] unless from_bookmarks
        manifest[:partOf] = [part_of] if series.present?
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
      { en: [manifest_label] }
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

    def part_of
      {
        id: "#{base_url.gsub('/catalog', '/series')}/#{series}/manifest",
        type: 'Collection'
      }
    end
  end
end
