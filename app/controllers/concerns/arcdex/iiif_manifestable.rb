module Arcdex
  module IiifManifestable
    extend ActiveSupport::Concern
    attr_reader :documents
    attr_accessor :document, :set_id

    delegate :id, :title, :image_url, :thumbnail_url, to: :document
    delegate :host_with_port, :protocol, to: :request

    def iiif_manifest
      @set_id = params[:id].split('-').first
      @documents = search_service.repository.search(
        { q: "parent_ids_ssim:\"#{set_id}\"", sort: 'sort_ssi asc', rows: 1_000 }
      ).documents

      respond_to do |format|
        format.json { render json: generate_manifest }
      end
    end

    def generate_manifest
      {
        '@context': presentation_api_url,
        id: "#{base_url}/manifest",
        start: {
          id: "#{base_url(id: params[:id])}/canvas",
          type: 'Canvas'
        },
        type: 'Manifest',
        label: { en: manifest_label },
        items: items,
        rights: rights_statement,
        requiredStatement: {
          label: { en: ['Attribution'] },
          value: { en: ['Data provided by <a href="https://pokemontcg.io/" target="_blank">Pokémon TCG Developers</a>'] }
        },
        homepage: [
          {
            id: base_url(id: set_id),
            type: 'Text',
            label: { en: ['View Set'] },
            format: 'text/html'
          }
        ]
      }
    end

    private

    def base_url(id: nil)
      Rails.application.routes.url_helpers.solr_document_url(
        id: id || document&.id || set_id,
        host: host_with_port,
        protocol: protocol
      )
    end

    def id_for(str)
      "#{base_url}/#{str}"
    end

    def presentation_api_url
      'http://iiif.io/api/presentation/3/context.json'
    end

    def rights_statement
      'http://rightsstatements.org/vocab/InC/1.0/'
    end

    def items
      documents.map do |doc|
        self.document = doc

        {
          id: id_for('canvas'),
          type: 'Canvas',
          height: 1024,
          width: 733,
          label: { en: [title] },
          items: [
            {
              id: id_for('page'),
              type: 'AnnotationPage',
              items: [
                {
                  id: id_for('annotation'),
                  type: 'Annotation',
                  motivation: 'painting',
                  body: {
                    id: image_url,
                    type: 'Image',
                    format: 'image/png'
                  },
                  target: id_for('canvas')
                }
              ]
            }
          ],
          metadata: canvas_metadata,
          thumbnail: [
            {
              id: thumbnail_url,
              type: 'Image',
              height: 342,
              width: 245,
              format: 'image/png'
            }
          ],
          homepage: [
            {
              id: base_url,
              type: 'Text',
              label: { en: ['View Card'] },
              format: 'text/html'
            }
          ]
        }
      end
    end

    def canvas_metadata
      fields = blacklight_config.component_indexed_terms_fields

      fields.keys.filter_map do |name|
        field = document[fields[name].field]
        next if field.blank?

        { label: { en: [name.titleize] }, value: { en: [metadata_value(fields[name].field)] } }
      end
    end

    def metadata_value(field)
      Array.wrap(document[field]).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')
    end

    def manifest_label
      series = Array.wrap(documents.first['series_ssm'])
      set = Array.wrap(documents.first['parent_unittitles_ssm'])
      ["#{series.first} - #{set.first}"]
    end
  end
end
