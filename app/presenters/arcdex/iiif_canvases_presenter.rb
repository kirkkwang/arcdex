module Arcdex
  class IiifCanvasesPresenter
    attr_reader :documents, :fields, :base_url
    attr_accessor :document

    delegate :id, :title, :image_url, :thumbnail_url, to: :document

    IMAGE_HEIGHT = 1024
    IMAGE_WIDTH = 733
    THUMBNAIL_HEIGHT = 342
    THUMBNAIL_WIDTH = 245

    def initialize(documents:, base_url:, fields:)
      @documents = documents
      @base_url = base_url
      @fields = fields
    end

    def as_json
      documents.map do |document|
        self.document = document

        {}.tap do |canvas|
          canvas[:id] = generate_id(id:, str: 'canvas')
          canvas[:type] = 'Canvas'
          canvas[:height] = IMAGE_HEIGHT
          canvas[:width] = IMAGE_WIDTH
          canvas[:label] = { en: [title] }
          canvas[:items] = [annotation_page]
          canvas[:metadata] = canvas_metadata
          canvas[:thumbnail] = [thumbnail_body]
          canvas[:homepage] = [homepage]
          canvas[:partOf] = [part_of] if document.series.present?
        end
      end
    end

    private

    def annotation_page
      {
        id: generate_id(id:, str: 'page'),
        type: 'AnnotationPage',
        items: [annotation]
      }
    end

    def annotation
      {
        id: generate_id(id:, str: 'annotation'),
        type: 'Annotation',
        motivation: 'painting',
        body: image_body,
        target: generate_id(id:, str: 'canvas')
      }
    end

    def image_body
      {
        id: image_url,
        type: 'Image',
        format: 'image/png'
      }
    end

    def thumbnail_body
      {
        id: thumbnail_url,
        type: 'Image',
        height: THUMBNAIL_HEIGHT,
        width: THUMBNAIL_WIDTH,
        format: 'image/png'
      }
    end

    def homepage
      {
        id: generate_id(id:),
        type: 'Text',
        label: { en: ['View Card'] },
        format: 'text/html'
      }
    end

    def generate_id(id:, str: '')
      File.join(base_url, id.to_s, str).chomp('/')
    end

    def canvas_metadata
      fields.keys.filter_map do |name|
        field = document[fields[name].field]
        next if field.blank?

        { label: { en: [name.titleize] }, value: { en: [metadata_value(fields[name].field)] } }
      end
    end

    def metadata_value(field)
      Array.wrap(document[field]).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')
    end

    def part_of
      {
        id: "#{base_url.gsub('/catalog', '/series')}/#{document.series}/manifest",
        type: 'Collection'
      }
    end
  end
end
