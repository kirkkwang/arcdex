module Arcdex
  module IiifPresentable
    extend ActiveSupport::Concern

    def thumbnail_height = 342

    def thumbnail_width = 245

    def presentation_api_url = 'http://iiif.io/api/presentation/3/context.json'

    def rights_statement = 'http://rightsstatements.org/vocab/InC/1.0/'

    def required_statement
      {
        label: { en: ['Attribution'] },
        value: { en: ['Data provided by <a href="https://pokemontcg.io/" target="_blank">Pokémon TCG Developers</a>'] }
      }
    end

    def thumbnail_body(url = nil)
      thumbnail_url = url || self.thumbnail_url
      {
        id: thumbnail_url,
        type: 'Image',
        height: thumbnail_height,
        width: thumbnail_width,
        format: 'image/png'
      }
    end
  end
end
